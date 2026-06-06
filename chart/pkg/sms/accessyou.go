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

package sms

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/OpenIMSDK/tools/errs"
	"github.com/OpenIMSDK/tools/log"

	"github.com/OpenIMSDK/chat/pkg/common/config"
)


func newAccessyou() (SMS, error) {
	return &accessyou{
		apiUrl:     config.Config.VerifyCode.Accessyou.ApiUrl,
		accountNo:  config.Config.VerifyCode.Accessyou.AccountNo,
		username:   config.Config.VerifyCode.Accessyou.Username,
		password:   config.Config.VerifyCode.Accessyou.Password,
		templateId: config.Config.VerifyCode.Accessyou.TemplateId,
	}, nil
}

type accessyou struct {
	apiUrl     string
	accountNo  string
	username   string
	password   string
	templateId string
}

func (s *accessyou) Name() string {
	return "accessyou-sms"
}

// accessyouResponse is the JSON response returned by the AccessYou OTP API.
type accessyouResponse struct {
	MsgStatus     string `json:"msg_status"`
	MsgStatusDesc string `json:"msg_status_desc"`
	MsgID         int64  `json:"msg_id"`
	PhoneNo       string `json:"phoneno"`
}

func (s *accessyou) SendCode(ctx context.Context, areaCode string, phoneNumber string, verifyCode string) error {
	apiUrl := s.apiUrl
	if apiUrl == "" {
		apiUrl = "https://otp.accessyou-api.com/sendsms-otp.php"
	}

	// Combine area code and phone number into international format.
	// areaCode may be like "+86" or "86"; strip the leading "+" if present.
	cleanAreaCode := strings.TrimPrefix(areaCode, "+")
	fullPhone := cleanAreaCode + phoneNumber

	params := url.Values{}
	params.Set("accountno", s.accountNo)
	params.Set("user", s.username)
	params.Set("pwd", s.password)
	params.Set("tid", s.templateId)
	params.Set("a", verifyCode) // template variable #a# = verification code
	params.Set("phone", fullPhone)

	fullUrl := fmt.Sprintf("%s?%s", apiUrl, params.Encode())
	resp, err := http.Get(fullUrl)
	if err != nil {
		return errs.Wrap(err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return errs.Wrap(err)
	}
	// Strip UTF-8 BOM if present (AccessYou response starts with \xEF\xBB\xBF)
	body = bytes.TrimPrefix(body, []byte{0xEF, 0xBB, 0xBF})

	// AccessYou OTP API returns JSON.
	// Success: msg_status = "100"
	// Errors: 101=login empty, 102=msg empty, 103=phone empty,
	//         104=IP forbidden, 105=login failure, 106=account disabled,
	//         107=insufficient balance, 108=phone format error,
	//         887=submission failure, 888=system error
	var result accessyouResponse
	if jsonErr := json.Unmarshal(body, &result); jsonErr != nil {
		log.ZError(ctx, "accessyou: failed to parse response", fmt.Errorf("%w", jsonErr), "body", string(body), "phone", fullPhone)
		return errs.Wrap(fmt.Errorf("accessyou: failed to parse response: %w, body: %s", jsonErr, string(body)))
	}

	if result.MsgStatus != "100" {
		log.ZError(ctx, "accessyou: send sms failed", fmt.Errorf("status=%s", result.MsgStatus), "phone", fullPhone, "status", result.MsgStatus, "desc", result.MsgStatusDesc)
		return errs.Wrap(fmt.Errorf("accessyou: send failed, status=%s desc=%s", result.MsgStatus, result.MsgStatusDesc))
	}

	log.ZError(ctx, "accessyou: send sms success", nil, "phone", fullPhone, "msgID", fmt.Sprintf("%d", result.MsgID))
	return nil
}
