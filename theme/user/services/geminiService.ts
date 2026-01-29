import { GoogleGenAI, Type } from "@google/genai";
import { EstimateResult } from "../types";

const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });

export const analyzeCarDamage = async (base64Image: string): Promise<EstimateResult> => {
  try {
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash-image',
      contents: {
        parts: [
          {
            inlineData: {
              mimeType: 'image/jpeg',
              data: base64Image
            }
          },
          {
            text: `
              You are a cute, friendly mechanic robot named "Cloudy". 
              Analyze this car image for damage.
              Please provide the output in JSON format.
              The currency should be KRW (Korean Won).
              
              Required JSON structure:
              {
                "damageAnalysis": "A brief, friendly description of the damage in Korean.",
                "estimatedCostMin": number (integer only),
                "estimatedCostMax": number (integer only),
                "repairSteps": ["Step 1 in Korean", "Step 2 in Korean", ...],
                "funFact": "A cheering, cute message for the driver in Korean (e.g. 'Don't worry, we'll fix it!')."
              }
            `
          }
        ]
      },
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            damageAnalysis: { type: Type.STRING },
            estimatedCostMin: { type: Type.NUMBER },
            estimatedCostMax: { type: Type.NUMBER },
            repairSteps: { 
              type: Type.ARRAY,
              items: { type: Type.STRING }
            },
            funFact: { type: Type.STRING }
          },
          required: ["damageAnalysis", "estimatedCostMin", "estimatedCostMax", "repairSteps", "funFact"]
        }
      }
    });

    const text = response.text;
    if (!text) throw new Error("No response from AI");
    
    return JSON.parse(text) as EstimateResult;

  } catch (error) {
    console.error("Error analyzing image:", error);
    throw error;
  }
};
