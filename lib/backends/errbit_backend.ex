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
    url = "https://errbit.services.lokalebasen.dk/notifier_api/v2/notices"
    IO.inspect HTTPotion.post(url, xml,["Content-Type": "application/xml"])
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


  defp api_key do
    System.get_env("ERRBIT_API_KEY")
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
    env = Mix.env |> Atom.to_string
    {:"server-environment", nil,
      [
        {:"project-root", nil, Mix.Project.app_path},
        {:"environment-name", nil, Mix.env},
        {:"app-version", nil, Mix.Project.config[:version]}
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
    {function, 0} = stackinfo[:function]
    {:error, nil,
      [
        {:class, nil, stackinfo[:module]},
        {:message, nil, message},
        {:backtrace, nil, [
            {:line, %{method: function, file: stackinfo[:module], number: stackinfo[:line]}, nil}
          ]
        }
      ]
    }
  end

end
