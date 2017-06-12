defmodule Protox.Conformance.Escript do

  @moduledoc false

  def run() do
    :io.setopts(:standard_io, encoding: :latin1)

    "./conformance_report.txt"
    |> File.open!([:write])
    |> loop()
  end


  defp loop(log_file) do
    IO.binwrite(log_file, "\n---------\n")

    case IO.binread(:stdio, 4) do
      :eof ->
        IO.binwrite(log_file, "EOF\n")
        :ok

      {:error, reason} ->
        IO.binwrite(log_file, "Error: #{inspect reason}\n")
        {:error, reason}

      <<len::unsigned-little-32>> ->
        :stdio
        |> IO.binread(len)
        |> dump_data(log_file)
        |> ConformanceRequest.decode()
        |> handle_request(log_file)
        |> make_message_bytes()
        |> output(log_file)

        loop(log_file)
    end
  end


  defp handle_request(
    {
      :ok,
      req = %ConformanceRequest{
        requested_output_format: :PROTOBUF,
        payload: {:protobuf_payload, _}
      }
    },
    log_file
  ) do
    IO.binwrite(log_file, "Will parse protobuf, output to protobuf\n")

    {:protobuf_payload, payload} = req.payload
    case TestAllTypes.decode(payload) do
      {:ok, msg} ->
        IO.binwrite(log_file, "Parse: success.\n")
        encoded_payload = msg |> Protox.Encode.encode() |> :binary.list_to_bin()
        %ConformanceResponse{result: {:protobuf_payload, encoded_payload}}

      {:error, reason} ->
        IO.binwrite(log_file, "Parse error: #{inspect reason}\n")
        %ConformanceResponse{result: {:parse_error, "Parse error: #{inspect reason}"}}
    end
  end


  defp handle_request(
    {
      :ok,
      req = %ConformanceRequest{
        requested_output_format: :JSON,
        payload: {:protobuf_payload, _}
      }
    },
    log_file
  ) do
    IO.binwrite(log_file, "Will parse protobuf; output to JSON\n")

    {:protobuf_payload, payload} = req.payload
    case TestAllTypes.decode(payload) do
      {:ok, msg} ->
        IO.binwrite(log_file, "Parse: success.\n")
        encoded_payload = msg |> Protox.EncodeJson.encode()
        IO.binwrite(log_file, "#{inspect msg}\n")
        IO.binwrite(log_file, "\n")
        IO.binwrite(log_file, "#{encoded_payload}\n")
        %ConformanceResponse{result: {:json_payload, encoded_payload}}

      {:error, reason} ->
        IO.binwrite(log_file, "Parse error: #{inspect reason}\n")
        %ConformanceResponse{result: {:parse_error, "Parse error: #{inspect reason}"}}
    end
  end


  defp handle_request({:ok, req}, log_file) do
    skip_reason = case {req.requested_output_format, req.payload} do
      {:UNSPECIFIED, _} ->
        "unspecified output"

      {:JSON, {_, _}} ->
        "json output"

      {:PROTOBUF, {:json_payload, _}} ->
        "json input"
    end
    IO.binwrite(log_file, "SKIPPED\n")
    IO.binwrite(log_file, "Reason: #{inspect skip_reason}\n")
    IO.binwrite(log_file, "#{inspect req}\n")
    %ConformanceResponse{result: {:skipped, "SKIPPED"}}
  end


  defp handle_request({:error, reason}, log_file) do
    IO.binwrite(log_file, "ConformanceRequest parse error: #{inspect reason}\n")
    %ConformanceResponse{result: {:parse_error, "Parse error: #{inspect reason}"}}
  end


  defp dump_data(data, log_file) do
    IO.binwrite(log_file, "Received #{inspect data}\n")
    data
  end


  defp output(data, log_file) do
    IO.binwrite(log_file, "Will write #{byte_size(data)} bytes\n")
    IO.binwrite(:stdio, data)
  end


  defp make_message_bytes(msg) do
    data = msg |> Protox.Encode.encode() |> :binary.list_to_bin()
    <<byte_size(data)::unsigned-little-32, data::binary>>
  end

end
