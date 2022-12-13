defmodule WeChat.Work.OA.Approval do
  @moduledoc """
  审批

  [文档-概述](https://developer.work.weixin.qq.com/document/path/91956)
  """

  import Jason.Helpers
  alias WeChat.Work

  @doc_link WeChat.Utils.work_doc_link_prefix()

  @typedoc "模板的唯一标识id"
  @type template_id :: String.t()
  @type timestamp :: integer
  @typedoc "分页查询游标，默认为0，后续使用返回的next_cursor进行分页拉取"
  @type cursor :: integer
  @typedoc "一次请求拉取审批单数量，默认值为100，上限值为100。若accesstoken为自建应用，仅允许获取在应用可见范围内申请人提交的表单，返回的sp_no_list个数可能和size不一致，开发者需用next_cursor判断表单记录是否拉取完"
  @type size :: integer
  @typedoc """
  筛选类型

  - `template_id` - 模板类型/模板id；
  - `creator` - 申请人；
  - `department` - 审批单提单者所在部门；
  - `sp_status` - 审批状态;
  - `record_type` - 审批单类型属性，1-请假；2-打卡补卡；3-出差；4-外出；5-加班； 6- 调班；7-会议室预定；8-退款审批；9-红包报销审批

  注意

  1. 仅“部门”支持同时配置多个筛选条件。
  2. 不同类型的筛选条件之间为“与”的关系，同类型筛选条件之间为“或”的关系
  3. record_type筛选类型仅支持2021/05/31以后新提交的审批单，历史单不支持表单类型属性过滤
  """
  @type filter_key :: String.t()
  @typedoc """
  筛选值

  对应为：

  - `template_id` - 模板id
  - `creator` - 申请人userid
  - `department` - 所在部门id
  - `sp_status` - 审批单状态
    - `1` - 审批中
    - `2` - 已通过
    - `3` - 已驳回
    - `4` - 已撤销
    - `6` - 通过后撤销
    - `7` - 已删除
    - `10` - 已支付
  """
  @type filter_value :: String.t()
  @typedoc "筛选条件，可对批量拉取的审批申请设置约束条件，支持设置多个条件"
  @type filters :: [{filter_key, filter_value}]
  @typedoc "审批单编号"
  @type sp_no :: String.t()

  @doc """
  获取审批模板详情
  - [官方文档](#{@doc_link}/92631){:target="_blank"}
  """
  @spec get_template_detail(Work.client(), Work.agent(), template_id) :: WeChat.response()
  def get_template_detail(client, agent, template_id) do
    client.post("/cgi-bin/oa/gettemplatedetail", json_map(template_id: template_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  提交审批申请
  - [官方文档](#{@doc_link}/92632){:target="_blank"}
  """
  @spec apply_event(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def apply_event(client, agent, body) do
    client.post("/cgi-bin/oa/applyevent", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  批量获取审批单号
  - [官方文档](#{@doc_link}/94603){:target="_blank"}
  """
  @spec list_approvals(
          Work.client(),
          Work.agent(),
          start_time :: timestamp,
          end_time :: timestamp,
          cursor,
          size,
          filters
        ) :: WeChat.response()
  def list_approvals(client, agent, start_time, end_time, cursor, size, filters \\ nil) do
    json =
      if filters do
        filters =
          Enum.map(filters, fn {key, value} ->
            json_map(key: key, value: value)
          end)

        json_map(
          starttime: start_time,
          endtime: end_time,
          cursor: cursor,
          size: size,
          filters: filters
        )
      else
        json_map(
          starttime: start_time,
          endtime: end_time,
          cursor: cursor,
          size: size
        )
      end

    client.post("/cgi-bin/oa/getapprovalinfo", json,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取审批申请详情
  - [官方文档](#{@doc_link}/92634){:target="_blank"}
  """
  @spec get_approval_detail(Work.client(), Work.agent(), sp_no) :: WeChat.response()
  def get_approval_detail(client, agent, sp_no) do
    client.post("/cgi-bin/oa/getapprovaldetail", json_map(sp_no: sp_no),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
