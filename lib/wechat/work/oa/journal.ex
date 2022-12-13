defmodule WeChat.Work.OA.Journal do
  @moduledoc """
  汇报

  目前，企业微信汇报应用对企业内部提供了以下接口和能力：

  - 1、获取汇报记录详情。
    即获取一段时间内，员工填写的详细汇报内容。

  - 2、获取汇报统计详情。
    即获取一段时间内，某个汇报的统计情况，即已汇报成员统计、未汇报成员统计等。
  """

  import Jason.Helpers
  alias WeChat.Work

  @doc_link WeChat.Utils.work_doc_link_prefix()

  @type timestamp :: integer
  @typedoc "游标首次请求传0，非首次请求携带上一次请求返回的next_cursor"
  @type cursor :: integer
  @typedoc "拉取条数"
  @type limit :: integer
  @typedoc """
  筛选类型

  不多于256字节

  - `creator`: 指定汇报记录提单人
  - `department`: 指定提单人所在部门
  - `template_id`: 指定模板
  """
  @type filter_key :: String.t()
  @typedoc "筛选值"
  @type filter_value :: String.t()
  @typedoc "过滤条件"
  @type filters :: [{filter_key, filter_value}]
  @typedoc "汇报记录ID"
  @type journal_uuid :: String.t()
  @typedoc "汇报表单id"
  @type template_id :: String.t()

  @doc """
  批量获取汇报记录单号
  - [官方文档](#{@doc_link}/93393){:target="_blank"}
  """
  @spec list_records(
          Work.client(),
          Work.agent(),
          start_time :: timestamp,
          end_time :: timestamp,
          cursor,
          limit,
          filters
        ) :: WeChat.response()
  def list_records(client, agent, start_time, end_time, cursor, limit, filters \\ nil) do
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
          limit: limit,
          filters: filters
        )
      else
        json_map(
          starttime: start_time,
          endtime: end_time,
          cursor: cursor,
          limit: limit
        )
      end

    client.post("/cgi-bin/oa/journal/get_record_list", json,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取汇报记录详情
  - [官方文档](#{@doc_link}/93394){:target="_blank"}
  """
  @spec get_record_detail(Work.client(), Work.agent(), journal_uuid) :: WeChat.response()
  def get_record_detail(client, agent, journal_uuid) do
    client.post("/cgi-bin/oa/journal/get_record_detail", json_map(journaluuid: journal_uuid),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取汇报统计数据
  - [官方文档](#{@doc_link}/93395){:target="_blank"}
  """
  @spec list_stats(
          Work.client(),
          Work.agent(),
          template_id,
          start_time :: timestamp,
          end_time :: timestamp
        ) :: WeChat.response()
  def list_stats(client, agent, template_id, start_time, end_time) do
    client.post(
      "/cgi-bin/oa/journal/get_stat_list",
      json_map(
        template_id: template_id,
        starttime: start_time,
        endtime: end_time
      ),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  导出汇报文档
  - [官方文档](#{@doc_link}/96108){:target="_blank"}
  """
  @spec export_doc(Work.client(), Work.agent(), journal_uuid, doc_id :: String.t()) ::
          WeChat.response()
  def export_doc(client, agent, journal_uuid, doc_id) do
    client.post(
      "/cgi-bin/oa/journal/export_doc",
      json_map(journaluuid: journal_uuid, docid: doc_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  下载微盘文件
  - [官方文档](#{@doc_link}/98021){:target="_blank"}
  """
  @spec download_we_drive_file(
          Work.client(),
          Work.agent(),
          journal_uuid,
          Work.WeDrive.FileManagement.file_id()
        ) :: WeChat.response()
  def download_we_drive_file(client, agent, journal_uuid, file_id) do
    client.post(
      "/cgi-bin/oa/journal/download_wedrive_file",
      json_map(journaluuid: journal_uuid, fileid: file_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
