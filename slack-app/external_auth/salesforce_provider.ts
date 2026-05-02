import { DefineOAuth2Provider, Schema } from "deno-slack-sdk/mod.ts";

const SalesforceProvider = DefineOAuth2Provider({
  provider_key: "salesforce_staffing",
  provider_type: Schema.providers.oauth2.CUSTOM,
  options: {
    provider_name: "Salesforce",
    authorization_url: "https://login.salesforce.com/services/oauth2/authorize",
    token_url: "https://login.salesforce.com/services/oauth2/token",
    client_id:
      "3MVG9gYjOgxHsENJKf14tBjOmdhtXfgDVkbQfaDA0OhqDb0G_1yEuyqXeDY.Dl_ioKG9azQ7vnGFDqa3F_9hS",
    scope: ["api", "refresh_token"],
    identity_config: {
      url: "https://login.salesforce.com/services/oauth2/userinfo",
      account_identifier: "$.preferred_username",
    },
  },
});

export default SalesforceProvider;
