"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
exports.__esModule = true;
exports.lambdaHandler = void 0;
var client_rekognition_1 = require("@aws-sdk/client-rekognition");
var node_fetch_1 = require("node-fetch");
var exponential_backoff_1 = require("exponential-backoff");
var file_type_1 = require("file-type");
var rekognition = new client_rekognition_1.RekognitionClient({
    region: "eu-west-1"
});
var errorResponse = function (statusCode, errorMessage) {
    return {
        headers: {
            "Content-Type": "application/json"
        },
        statusCode: statusCode,
        body: JSON.stringify({
            error: errorMessage
        })
    };
};
var fetchImage = function (imageURL) { return __awaiter(void 0, void 0, void 0, function () {
    var response, buffer, error_1;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                _a.trys.push([0, 3, , 4]);
                return [4 /*yield*/, (0, exponential_backoff_1.backOff)(function () { return (0, node_fetch_1["default"])(imageURL, { method: "GET" }); })];
            case 1:
                response = _a.sent();
                return [4 /*yield*/, response.arrayBuffer()];
            case 2:
                buffer = _a.sent();
                return [2 /*return*/, buffer];
            case 3:
                error_1 = _a.sent();
                console.error(error_1);
                return [2 /*return*/, null];
            case 4: return [2 /*return*/];
        }
    });
}); };
var validateFileType = function (buffer) { return __awaiter(void 0, void 0, void 0, function () {
    var ft, error_2;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                _a.trys.push([0, 2, , 3]);
                return [4 /*yield*/, (0, file_type_1["default"])(buffer)];
            case 1:
                ft = _a.sent();
                return [2 /*return*/, (ft === null || ft === void 0 ? void 0 : ft.ext) === "jpg" || (ft === null || ft === void 0 ? void 0 : ft.ext) === "png"];
            case 2:
                error_2 = _a.sent();
                console.error(error_2);
                return [2 /*return*/, false];
            case 3: return [2 /*return*/];
        }
    });
}); };
var validateFileSize = function (buffer) {
    try {
        return buffer.byteLength < 5000000; // 5MB
    }
    catch (error) {
        console.error(error);
        return false;
    }
};
var parseRekognitionResponse = function (rekognitionResponse) {
    if (rekognitionResponse.ModerationLabels === undefined) {
        return [];
    }
    return rekognitionResponse.ModerationLabels.filter(function (label) { return label.ParentName === "" || label.ParentName === undefined; }).map(function (label) {
        return {
            confidence: label.Confidence,
            name: label.Name
        };
    });
};
var lambdaHandler = function (event, context) { return __awaiter(void 0, void 0, void 0, function () {
    var queryStringParameters, imageURL, imageBuffer, validFileType, image, input, command, result, parsedResponse, error_3;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                _a.trys.push([0, 4, , 5]);
                queryStringParameters = event.queryStringParameters || {};
                imageURL = queryStringParameters.url;
                if (imageURL === undefined) {
                    return [2 /*return*/, errorResponse(400, "No image URL provided")];
                }
                return [4 /*yield*/, fetchImage(imageURL)];
            case 1:
                imageBuffer = _a.sent();
                if (imageBuffer === null) {
                    return [2 /*return*/, errorResponse(404, "Image not found")];
                }
                return [4 /*yield*/, validateFileType(imageBuffer)];
            case 2:
                validFileType = _a.sent();
                if (!validFileType) {
                    return [2 /*return*/, errorResponse(400, "Invalid image format. Allowed formats are JPEG and PNG")];
                }
                if (!validateFileSize(imageBuffer)) {
                    return [2 /*return*/, errorResponse(400, "Image is too large. Files up to 5MB are allowed")];
                }
                image = { Bytes: new Uint8Array(imageBuffer) };
                input = {
                    Image: image,
                    MinConfidence: 50.0
                };
                command = new client_rekognition_1.DetectModerationLabelsCommand(input);
                return [4 /*yield*/, rekognition.send(command)];
            case 3:
                result = _a.sent();
                parsedResponse = parseRekognitionResponse(result);
                return [2 /*return*/, {
                        headers: {
                            "Content-Type": "application/json"
                        },
                        statusCode: 200,
                        body: JSON.stringify(parsedResponse)
                    }];
            case 4:
                error_3 = _a.sent();
                console.error(error_3);
                if (error_3 instanceof client_rekognition_1.InvalidImageFormatException) {
                    return [2 /*return*/, errorResponse(400, "Image is invalid")];
                }
                return [2 /*return*/, errorResponse(500, "Internal server error")];
            case 5: return [2 /*return*/];
        }
    });
}); };
exports.lambdaHandler = lambdaHandler;
