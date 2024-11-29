```bash
# required: dotnet tool install --global Datalust.ClefTool. Requirments: https://clef-json.org/
container_name="${args[0]}"
echo "docker compose logs --tail 5000 -f ""${container_name}"""
docker compose logs --tail 5000 -f "${container_name}" | stdbuf -oL sed -e "s/^${container_name}-[0-9]\+\s\|\s|\s//g" | \
  # Handle dapr logs as json, and make it compatible with clef
  stdbuf -oL sed -e 's/\"msg\"/\"@mt\"/g; s/\"time\"/\"@t\"/g; s/"level":"debug"/"@l":"Debug"/g; s/"level":"info"/"@l":"Information"/g; s/"level":"warning"/"@l":"Warning"/g; s/"level":"error"/"@l":"Error"/g' | \
  stdbuf -oL sed -e 's/"@l":"informational"/"@l":"Information"/g' | \
  # Handle non-json logs like exceptions in js to make them compatible
  stdbuf -oL sed -e '/^{/!s/\(.*\)/{\"@t\":\"0001-01-01T00:00:00.0000000Z\",\"@mt\":\"LINE: \1\"}/' | \
  # Parse json log with clef
  clef --format-template="[{@t:T} {@l:u3}] {@m:lj}{#if SourceContext is not null} ({Substring(SourceContext,LastIndexOf(SourceContext,'.')+1)}){#end}{NewLine()}{@x}"
```

```csharp
builder.Services.AddSerilog((services, lc) => lc
      .MinimumLevel.Information()
      .ReadFrom.Services(services)
      // NOTE: https://clef-json.org/
      .WriteTo.Console(new CompactJsonFormatter()));
```

```js
export enum LogEventLevel {
  Verbose,
  Debug,
  Information,
  Warning,
  Error,
  Fatal,
}

---

function stripAnsi(value: string): string {
  // eslint-disable-next-line no-control-regex
  return value.replace(/\u001b\[.*?m/g, "");
}

export function customISODateString() {
  const date = new Date();
  const isoString = date.toISOString();
  const enhancedPrecision = isoString.replace(/Z$/, "0000Z");
  return enhancedPrecision;
}

export function formatCompactJsonLog(msg: string, status: string): string {
  // NOTE: https://clef-json.org/
  const logEvent = {
    "@t": customISODateString(),
    "@m": stripAnsi(msg),
    "@l": status,
  };
  return JSON.stringify(logEvent);
}

export const logger = {
  error: (message: string) => logger.log(message, LogEventLevel[LogEventLevel.Error]),
  logRecord: (record: ServiceInvocationLogRecord) => logger.log(JSON.stringify(record)),
  log: (message: string, level: string = LogEventLevel[LogEventLevel.Information]) => {
    const logEntry = formatCompactJsonLog(message.toString(), level);
    console.log(logEntry);
  },
};

const viteLogger = createLogger(undefined, { prefix: "" });

const loggerInfo = viteLogger.info;
viteLogger.info = (msg, options) => {
  var jsonMessage = formatCompactJsonLog(msg, LogEventLevel[LogEventLevel.Information]);
  loggerInfo(jsonMessage, { timestamp: false });
};
const loggerWarn = viteLogger.warn;
viteLogger.warn = (msg, options) => {
  var jsonMessage = formatCompactJsonLog(msg, LogEventLevel[LogEventLevel.Warning]);
  loggerWarn(jsonMessage, { timestamp: false });
};
const loggerWarnOnce = viteLogger.warnOnce;
viteLogger.warnOnce = (msg, options) => {
  var jsonMessage = formatCompactJsonLog(msg, LogEventLevel[LogEventLevel.Warning]);
  loggerWarnOnce(jsonMessage, { timestamp: false });
};
const loggerError = viteLogger.error;
viteLogger.error = (msg, options) => {
  var jsonMessage = formatCompactJsonLog(msg, LogEventLevel[LogEventLevel.Error]);
  loggerError(jsonMessage, { timestamp: false });
};

export default viteLogger;

---

export function defineMorganTokens(name: string, headerRequest: string) {
  morgan.token(name, function (req, res) {
    const requestId = req.headers[headerRequest];
    return Array.isArray(requestId) ? requestId[0] : requestId || Guid.create().toString();
  });
}

function formatString(template: string, ...values: (string | number | undefined)[]): string {
  var index = 0;
  return template.replace(/{\w+}/g, (match) => {
    const replaced = values[index] != undefined && values[index] ? values[index]!.toString() : match;
    index += 1;
    return replaced;
  });
}

const morganCompactLogEventFormat = morgan((tokens, req, res) => {
  // NOTE: https://clef-json.org/
  const method = tokens.method(req, res) as string;
  var url = tokens.url(req, res);
  var statusCode = tokens.status(req, res);
  var responseTime = tokens["response-time"](req, res);

  const template = "{Method} {Url} {StatusCode} - {ResponseTime} ms";
  const logEvent = {
    "@t": customISODateString(),
    "@m": formatString(template, method, url, statusCode, responseTime),
    "@mt": template,
    "@l": LogEventLevel[LogEventLevel.Information],
    Method: method,
    Url: url,
    StatusCode: statusCode,
    ResponseTime: responseTime,
  };
  return JSON.stringify(logEvent);
});

export default morganCompactLogEventFormat;
```
