%dw 2.0
output application/json
---
{
  header: {
    apiName: Mule::p('api.name'),
    apiVersion: Mule::p('api.version'),
    correlationId: correlationId
  },
  error : {
      description : error.description default  "Generic Error",
      code: if(vars.errorCode != null) vars.errorCode else error.errorType.identifier,
      dateTime: now() as String { format: "yyyy-MM-dd'T'HH:mm:ss" },
      message: error.detailedDescription default  "Generic Error"
  }
}