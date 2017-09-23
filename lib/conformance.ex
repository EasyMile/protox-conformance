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
        |> Conformance.ConformanceRequest.decode()
        |> handle_request(log_file)
        |> make_message_bytes()
        |> output(log_file)

        loop(log_file)
    end
  end


  defp handle_request(
    {
      :ok,
      req = %Conformance.ConformanceRequest{
        requested_output_format: :PROTOBUF,
        payload: {:protobuf_payload, _},
      }
    },
    log_file
  ) do
    IO.binwrite(log_file, "Will parse protobuf\n")

    {:protobuf_payload, payload} = req.payload

    proto_type = case req.message_type do
      "protobuf_test_messages.proto3.TestAllTypesProto3" ->
        ProtobufTestMessages.Proto3.TestAllTypesProto3

      "protobuf_test_messages.proto2.TestAllTypesProto2" ->
        ProtobufTestMessages.Proto2.TestAllTypesProto2

      "" ->
        ProtobufTestMessages.Proto3.TestAllTypesProto3
    end

    case proto_type.decode(payload) do
      {:ok, msg} ->
        IO.binwrite(log_file, "Parse: success.\n")
        encoded_payload = msg |> Protox.Encode.encode() |> :binary.list_to_bin()
        %Conformance.ConformanceResponse{result: {:protobuf_payload, encoded_payload}}

      {:error, reason} ->
        IO.binwrite(log_file, "Parse error: #{inspect reason}\n")
        %Conformance.ConformanceResponse{result: {:parse_error, "Parse error: #{inspect reason}"}}
    end
  end


  # All JSON related tests are skipped.
  defp handle_request({:ok, req}, log_file) do
    skip_reason = case {req.requested_output_format, req.payload} do
      {:UNSPECIFIED, _} ->
        "unspecified input"

      {:JSON, _} ->
        "json input"

      {:PROTOBUF, {:json_payload, _}} ->
        "json output"
    end
    IO.binwrite(log_file, "SKIPPED\n")
    IO.binwrite(log_file, "Reason: #{inspect skip_reason}\n")
    IO.binwrite(log_file, "#{inspect req}\n")
    %Conformance.ConformanceResponse{result: {:skipped, "SKIPPED"}}
  end


  defp handle_request({:error, reason}, log_file) do
    IO.binwrite(log_file, "ConformanceRequest parse error: #{inspect reason}\n")
    %Conformance.ConformanceResponse{result: {:parse_error, "Parse error: #{inspect reason}"}}
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
