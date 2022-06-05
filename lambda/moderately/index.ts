import {
  RekognitionClient,
  DetectModerationLabelsCommand,
  DetectModerationLabelsCommandInput,
} from "@aws-sdk/client-rekognition";
import { APIGatewayEvent, APIGatewayProxyResult, Context } from "aws-lambda";

const rekognition: RekognitionClient = new RekognitionClient({
  region: "eu-west-1",
});

export const lambdaHandler = async (
  event: APIGatewayEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  try {
    const base64Image: string | null = event.body;
    if (!base64Image) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Missing image",
        }),
      };
    }
    const imageBytes = Buffer.from(base64Image, "base64");
    const input: DetectModerationLabelsCommandInput = {
      Image: { Bytes: imageBytes },
      MinConfidence: 0.0,
    };
    const command: DetectModerationLabelsCommand =
      new DetectModerationLabelsCommand(input);
    const result = await rekognition.send(command);
    return {
      statusCode: 200,
      body: JSON.stringify(result),
    };
  } catch (error) {
    console.log(error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Internal server error",
      }),
    };
  }
};
