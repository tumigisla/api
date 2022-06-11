import {
  RekognitionClient,
  DetectModerationLabelsCommand,
  DetectModerationLabelsCommandInput,
  DetectModerationLabelsCommandOutput,
  Image,
  InvalidImageFormatException,
} from "@aws-sdk/client-rekognition";
import { APIGatewayEvent, APIGatewayProxyResult, Context } from "aws-lambda";
import fetch from "node-fetch";
import { backOff } from "exponential-backoff";
import fileType, { FileTypeResult } from "file-type";

interface MyModerationLabel {
  confidence?: number;
  name?: string;
}

const rekognition: RekognitionClient = new RekognitionClient({
  region: "eu-west-1",
});

const errorResponse = (
  statusCode: number,
  errorMessage: string
): APIGatewayProxyResult => {
  return {
    headers: {
      "Content-Type": "application/json",
    },
    statusCode: statusCode,
    body: JSON.stringify({
      message: errorMessage,
    }),
  };
};

const fetchImage = async (imageURL: string): Promise<ArrayBuffer | null> => {
  try {
    const response = await backOff(() => fetch(imageURL, { method: "GET" }));
    const buffer: ArrayBuffer = await response.arrayBuffer();
    return buffer;
  } catch (error) {
    console.error(error);
    return null;
  }
};

const validateFileType = async (buffer: ArrayBuffer): Promise<boolean> => {
  try {
    const ft: FileTypeResult | null = await fileType(buffer);
    return ft?.ext === "jpg" || ft?.ext === "png";
  } catch (error) {
    console.error(error);
    return false;
  }
};

const validateFileSize = (buffer: ArrayBuffer): boolean => {
  try {
    return buffer.byteLength < 5000000; // 5MB
  } catch (error) {
    console.error(error);
    return false;
  }
};

const parseRekognitionResponse = (
  rekognitionResponse: DetectModerationLabelsCommandOutput
): MyModerationLabel[] => {
  if (rekognitionResponse.ModerationLabels === undefined) {
    return [];
  }
  return rekognitionResponse.ModerationLabels.filter(
    (label) => label.ParentName === "" || label.ParentName === undefined
  ).map((label) => {
    return {
      confidence: label.Confidence,
      name: label.Name,
    };
  });
};

export const lambdaHandler = async (
  event: APIGatewayEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  try {
    const queryStringParameters = event.queryStringParameters || {};
    const imageURL: string | undefined = queryStringParameters.url;
    if (imageURL === undefined) {
      return errorResponse(400, "No image URL provided");
    }

    const imageBuffer: ArrayBuffer | null = await fetchImage(imageURL);
    if (imageBuffer === null) {
      return errorResponse(404, "Image not found");
    }

    const validFileType: boolean = await validateFileType(imageBuffer);
    if (!validFileType) {
      return errorResponse(
        400,
        "Invalid image format. Allowed formats are JPEG and PNG"
      );
    }

    if (!validateFileSize(imageBuffer)) {
      return errorResponse(
        400,
        "Image is too large. Files up to 5MB are allowed"
      );
    }

    const image: Image = { Bytes: new Uint8Array(imageBuffer) };
    const input: DetectModerationLabelsCommandInput = {
      Image: image,
      MinConfidence: 50.0,
    };

    const command: DetectModerationLabelsCommand =
      new DetectModerationLabelsCommand(input);

    const result: DetectModerationLabelsCommandOutput = await rekognition.send(
      command
    );
    const parsedResponse = parseRekognitionResponse(result);

    return {
      headers: {
        "Content-Type": "application/json",
      },
      statusCode: 200,
      body: JSON.stringify(parsedResponse),
    };
  } catch (error) {
    console.error(error);
    if (error instanceof InvalidImageFormatException) {
      return errorResponse(400, "Image is invalid");
    }
    return errorResponse(500, "Internal server error");
  }
};
