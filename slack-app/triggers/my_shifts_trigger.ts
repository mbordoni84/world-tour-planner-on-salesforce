import type { Trigger } from "deno-slack-sdk/types.ts";
import { TriggerContextData, TriggerTypes } from "deno-slack-api/mod.ts";
import MyShiftsWorkflow from "../workflows/my_shifts_workflow.ts";

const myShiftsTrigger: Trigger<typeof MyShiftsWorkflow.definition> = {
  type: TriggerTypes.Shortcut,
  name: "My Shifts",
  description: "View your assigned shifts",
  workflow: `#/workflows/${MyShiftsWorkflow.definition.callback_id}`,
  inputs: {
    user_id: { value: TriggerContextData.Shortcut.user_id },
    channel_id: { value: TriggerContextData.Shortcut.channel_id },
  },
};

export default myShiftsTrigger;
