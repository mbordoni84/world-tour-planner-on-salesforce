import { Manifest } from "deno-slack-sdk/mod.ts";
import SalesforceProvider from "./external_auth/salesforce_provider.ts";
import MyShiftsWorkflow from "./workflows/my_shifts_workflow.ts";
import AvailableWorkflow from "./workflows/available_workflow.ts";
import OverlapsWorkflow from "./workflows/overlaps_workflow.ts";
import RenderHomeWorkflow from "./workflows/render_home_workflow.ts";
import NotifyShiftChangeWorkflow from "./workflows/notify_shift_change_workflow.ts";
import NotifyOwnerWorkflow from "./workflows/notify_owner_workflow.ts";
import DailyDigestWorkflow from "./workflows/daily_digest_workflow.ts";
import RequestAccountWorkflow from "./workflows/request_account_workflow.ts";
import DisconnectWorkflow from "./workflows/disconnect_workflow.ts";
import ConnectWorkflow from "./workflows/connect_workflow.ts";

export default Manifest({
  name: "World Tour Staffing",
  description:
    "Manage your event shifts directly from Slack — view, claim, drop, and check overlaps.",
  icon: "assets/default_new_app_icon.png",
  workflows: [
    MyShiftsWorkflow,
    AvailableWorkflow,
    OverlapsWorkflow,
    RenderHomeWorkflow,
    NotifyShiftChangeWorkflow,
    NotifyOwnerWorkflow,
    DailyDigestWorkflow,
    RequestAccountWorkflow,
    DisconnectWorkflow,
    ConnectWorkflow,
  ],
  outgoingDomains: [
    "login.salesforce.com",
    "test.salesforce.com",
    "storm-973b1cdf0acdf3.my.salesforce.com",
  ],
  externalAuthProviders: [SalesforceProvider],
  botScopes: [
    "commands",
    "chat:write",
    "chat:write.public",
    "users:read",
    "users:read.email",
    "im:write",
  ],
});
