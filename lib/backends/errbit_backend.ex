defmodule ErrbitBackend do
  use GenEvent
  use Timex

  def init({__MODULE__, name}) do
    {:ok, []}
  end

  def handle_event({:error, _pid, info}, parent) do
    {Logger, msg, timestamp, stackinfo} = info
    timestamp = timestamp |> Date.from("GMT") |> DateFormat.format!("{ISO}")
    xml = xml(msg, stackinfo)
    HTTPotion.post(errbit_url, xml,["Content-Type": "application/xml"])
    {:ok, parent}
  end

  def handle_event(_, parent), do: {:ok, parent}

  @doc """
  <?xml version="1.0" encoding="UTF-8"?>
  <notice version="2.3">
    <api-key>...</api-key>
    <notifier>...</notifier>
    <error>...</error>
    <request>...</request>
    <server-environment>...</server-environment>
  </notice>
  """
  defp xml(message, stackinfo) do

    request =
      {:notice, %{version: "2.3"},
        [
          {:"api-key", nil, api_key},
          notifier,
          error(message, stackinfo),
          # request,
          server_environment
        ]
      }
    request |> XmlBuilder.generate

  end

  defp errbit_url do
    uri = URI.parse(System.get_env("ERRBIT_URL"))
    "#{uri.scheme}://#{uri.host}/notifier_api/v2/notices"
  end

  defp api_key do
    URI.parse(System.get_env("ERRBIT_URL")).userinfo
  end

  @doc """
  <notifier>
    <name>Curl Notifier</name>
    <version>1.0.0</version>
    <url>http://api.airbrake.io</url>
  </notifier>
  """
  defp notifier do
    {:notifier, nil,
      [
        {:name, nil, "Syncex.ErrbitBackend - Logger"},
        {:version, nil, "1.0.0"},
        {:url, nil, "http://api.airbrake.io"}
      ]
    }
  end

  @doc """
  <server-environment>
    <project-root>/testapp</project-root>
    <environment-name>production</environment-name>
    <app-version>1.0.0</app-version>
  </server-environment>
  """
  defp server_environment do
    {:"server-environment", nil,
      [
        {:"project-root", nil, Application.get_env(:syncex, :app_path)},
        {:"environment-name", nil, Mix.env},
        {:"app-version", nil, Application.get_env(:syncex, :version)}
      ]
    }
  end

  @doc """
  <request>
    <url>http://example.com</url>
    <component/>
    <action/>
    <cgi-data>
      <var key="SERVER_NAME">example.org</var>
      <var key="HTTP_USER_AGENT">Mozilla</var>
    </cgi-data>
  </request>
  """
  defp request do
    {:request, nil,
      [
        {:url, nil, "http://example.com"},
        {:component, nil, nil},
        {:action, nil, nil},
        {:"cgi-data", nil, [
            {:var, %{key: "SERVER_NAME"}, "example.org"},
            {:var, %{key: "HTTP_USER_AGENT"}, "Mozilla"}
          ]
        }
      ]
    }
  end

  @doc """
  <error>
    <class>RuntimeError</class>
    <message>RuntimeError: I've made a huge mistake</message>
    <backtrace>
      <line method="public" file="/testapp/app/models/user.rb" number="53"/>
      <line method="index" file="/testapp/app/controllers/users_controller.rb" number="14"/>
    </backtrace>
  </error>
  """
  defp error(message, stackinfo) do
    function = fetch_function(stackinfo[:function])
    module = fetch_module(stackinfo[:module])
    line = fetch_line(stackinfo[:line])
    {:error, nil,
      [
        {:class, nil, stackinfo[:module]},
        {:message, nil, message},
        {:backtrace, nil, [
            {:line, %{method: function, file: module, number: line}, nil}
          ]
        }
      ]
    }
  end

  defp fetch_function({function, _}), do: function
  defp fetch_function(_),             do: "Unknown function"

  defp fetch_module({module, _}), do: module
  defp fetch_module(_),           do: "Unknown module"

  defp fetch_line({line, _}), do: line
  defp fetch_line(_),         do: "Unknown line"

end
