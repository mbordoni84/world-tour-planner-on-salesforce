import { DefineWorkflow, Schema } from "deno-slack-sdk/mod.ts";
import { RenderHomeDefinition } from "../functions/render_home.ts";

const RenderHomeWorkflow = DefineWorkflow({
  callback_id: "render_home_workflow",
  title: "Render App Home",
  input_parameters: {
    properties: {
      user_id: { type: Schema.slack.types.user_id },
    },
    required: ["user_id"],
  },
});

RenderHomeWorkflow.addStep(RenderHomeDefinition, {
  user_id: RenderHomeWorkflow.inputs.user_id,
});

export default RenderHomeWorkflow;
