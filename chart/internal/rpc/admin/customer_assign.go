package admin

import (
	"context"
	constant2 "github.com/OpenIMSDK/chat/pkg/common/constant"
	table "github.com/OpenIMSDK/chat/pkg/common/db/table/admin"
	"github.com/OpenIMSDK/chat/pkg/common/mctx"
	"github.com/OpenIMSDK/chat/pkg/proto/admin"
	"github.com/OpenIMSDK/tools/errs"
	"github.com/OpenIMSDK/tools/utils"
	"time"
)

func agentToPb(a *table.CustomerAgent) *admin.CustomerAgentInfo {
	return &admin.CustomerAgentInfo{
		AgentID:    a.AgentID,
		UserID:     a.UserID,
		AgentName:  a.AgentName,
		Status:     a.Status,
		MaxLoad:    a.MaxLoad,
		CurLoad:    a.CurLoad,
		CreateTime: a.CreateTime.UnixMilli(),
	}
}

func (o *adminServer) CreateCustomerAgent(ctx context.Context, req *admin.CreateCustomerAgentReq) (*admin.CreateCustomerAgentResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if req.UserID == "" {
		return nil, errs.ErrArgs.Wrap("userID不能为空")
	}
	maxLoad := req.MaxLoad
	if maxLoad <= 0 {
		maxLoad = 50
	}
	agent := &table.CustomerAgent{
		AgentID:   utils.Md5(req.UserID + time.Now().String()),
		UserID:    req.UserID,
		AgentName: req.AgentName,
		Status:    int32(constant2.CustomerAgentStatusActive),
		MaxLoad:   maxLoad,
	}
	if err := o.Database.CreateCustomerAgent(ctx, agent); err != nil {
		return nil, err
	}
	return &admin.CreateCustomerAgentResp{Agent: agentToPb(agent)}, nil
}

func (o *adminServer) UpdateCustomerAgent(ctx context.Context, req *admin.UpdateCustomerAgentReq) (*admin.UpdateCustomerAgentResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	update := map[string]any{}
	if req.AgentName != "" {
		update["agent_name"] = req.AgentName
	}
	if req.Status != 0 {
		update["status"] = req.Status
	}
	if req.MaxLoad > 0 {
		update["max_load"] = req.MaxLoad
	}
	if len(update) == 0 {
		return &admin.UpdateCustomerAgentResp{}, nil
	}
	if err := o.Database.UpdateCustomerAgent(ctx, req.AgentID, update); err != nil {
		return nil, err
	}
	return &admin.UpdateCustomerAgentResp{}, nil
}

func (o *adminServer) DeleteCustomerAgent(ctx context.Context, req *admin.DeleteCustomerAgentReq) (*admin.DeleteCustomerAgentResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if err := o.Database.DeleteCustomerAgent(ctx, req.AgentID); err != nil {
		return nil, err
	}
	return &admin.DeleteCustomerAgentResp{}, nil
}

func (o *adminServer) SearchCustomerAgents(ctx context.Context, req *admin.SearchCustomerAgentsReq) (*admin.SearchCustomerAgentsResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	total, agents, err := o.Database.SearchCustomerAgents(ctx, req.Keyword, req.Pagination.PageNumber, req.Pagination.ShowNumber)
	if err != nil {
		return nil, err
	}
	pbAgents := make([]*admin.CustomerAgentInfo, 0, len(agents))
	for _, a := range agents {
		pbAgents = append(pbAgents, agentToPb(a))
	}
	return &admin.SearchCustomerAgentsResp{Total: total, Agents: pbAgents}, nil
}

// AssignCustomer 分配客户给坐席（手动/自动轮询）
func (o *adminServer) AssignCustomer(ctx context.Context, req *admin.AssignCustomerReq) (*admin.AssignCustomerResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	var agent *table.CustomerAgent
	var err error
	assignType := int32(constant2.CustomerAssignTypeAuto)
	opUserID := mctx.GetOpUserID(ctx)

	if req.AgentID != "" {
		// 手动指定坐席
		agent, err = o.Database.GetCustomerAgent(ctx, req.AgentID)
		if err != nil {
			return nil, err
		}
		assignType = int32(constant2.CustomerAssignTypeManual)
	} else {
		// 自动轮询：加分布式锁防止并发竞态（多个请求同时抢占同一坐席）
		unlock, lockErr := o.Database.AcquireRoundRobinLock(ctx)
		if lockErr != nil {
			return nil, lockErr
		}
		defer unlock()

		agent, err = o.Database.NextRoundRobinAgent(ctx)
		if err != nil {
			return nil, errs.ErrInternalServer.Wrap("暂无可用坐席")
		}
	}

	assign := &table.CustomerAssign{
		CustomerID: req.CustomerID,
		AgentID:    agent.AgentID,
		AssignType: assignType,
		AssignedBy: opUserID,
	}
	if err := o.Database.UpsertCustomerAssign(ctx, assign); err != nil {
		return nil, err
	}
	// 修复：IncrAgentLoad 错误不再忽略，分配失败需返回错误
	if err := o.Database.IncrAgentLoad(ctx, agent.AgentID, 1); err != nil {
		return nil, err
	}

	return &admin.AssignCustomerResp{Agent: agentToPb(agent)}, nil
}

// GetMyAgent 用户查询自己被分配的坐席
func (o *adminServer) GetMyAgent(ctx context.Context, req *admin.GetMyAgentReq) (*admin.GetMyAgentResp, error) {
	opUserID := mctx.GetOpUserID(ctx)
	assign, err := o.Database.GetCustomerAssign(ctx, opUserID)
	if err != nil {
		return nil, err
	}
	agent, err := o.Database.GetCustomerAgent(ctx, assign.AgentID)
	if err != nil {
		return nil, err
	}
	return &admin.GetMyAgentResp{Agent: agentToPb(agent)}, nil
}

func (o *adminServer) ListAgentCustomers(ctx context.Context, req *admin.ListAgentCustomersReq) (*admin.ListAgentCustomersResp, error) {
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	total, assigns, err := o.Database.ListAgentCustomers(ctx, req.AgentID, req.Pagination.PageNumber, req.Pagination.ShowNumber)
	if err != nil {
		return nil, err
	}
	customerIDs := make([]string, 0, len(assigns))
	for _, a := range assigns {
		customerIDs = append(customerIDs, a.CustomerID)
	}
	return &admin.ListAgentCustomersResp{Total: total, CustomerIDs: customerIDs}, nil
}
