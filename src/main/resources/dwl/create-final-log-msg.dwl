%dw 2.0
output application/json
---
{
	correlationId: correlationId,
	applicationName: Mule::p('api.name'),
	applicationVersion: Mule::p('api.version'),
	environment: Mule::p('mule.env'),
	priority: vars.logLevel,
	category: Mule::p('mule.logging.prefix') as String ++ ".logging",
	timestamp: now(),
	(content: payload) if(vars.logLevel == 'DEBUG' or vars.logLevel == 'ERROR'),
	locationInfo: {
		"rootContainer": flow.name
	}
} ++ vars.logMessage