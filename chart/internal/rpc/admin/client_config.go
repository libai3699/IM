// Copyright © 2023 OpenIM open source community. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package admin

import (
	"context"

	"github.com/OpenIMSDK/tools/log"

	"github.com/OpenIMSDK/tools/errs"

	"github.com/OpenIMSDK/chat/pkg/common/mctx"
	"github.com/OpenIMSDK/chat/pkg/proto/admin"
)

// sensitiveConfigKeys 不允许通过用户侧公开接口返回的敏感配置项
var sensitiveConfigKeys = []string{"super_code"}

func (o *adminServer) GetClientConfig(ctx context.Context, req *admin.GetClientConfigReq) (*admin.GetClientConfigResp, error) {
	defer log.ZDebug(ctx, "return")
	conf, err := o.Database.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	// 内部调用（如登录验证）不过滤；外部非管理员请求过滤敏感字段
	if !mctx.IsInternalCall(ctx) {
		if _, err := mctx.CheckAdmin(ctx); err != nil {
			for _, key := range sensitiveConfigKeys {
				delete(conf, key)
			}
		}
	}
	return &admin.GetClientConfigResp{Config: conf}, nil
}

func (o *adminServer) SetClientConfig(ctx context.Context, req *admin.SetClientConfigReq) (*admin.SetClientConfigResp, error) {
	defer log.ZDebug(ctx, "return")
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if len(req.Config) == 0 {
		return nil, errs.ErrArgs.Wrap("更新配置不能为空")
	}
	if err := o.Database.SetConfig(ctx, req.Config); err != nil {
		return nil, err
	}
	return &admin.SetClientConfigResp{}, nil
}

func (o *adminServer) DelClientConfig(ctx context.Context, req *admin.DelClientConfigReq) (*admin.DelClientConfigResp, error) {
	defer log.ZDebug(ctx, "return")
	if _, err := mctx.CheckAdmin(ctx); err != nil {
		return nil, err
	}
	if err := o.Database.DelConfig(ctx, req.Keys); err != nil {
		return nil, err
	}
	return &admin.DelClientConfigResp{}, nil
}
