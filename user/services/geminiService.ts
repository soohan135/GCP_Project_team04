import { GoogleGenAI } from "@google/genai";
import { DamageEstimate } from "../types";

// Helper to convert file to base64
export const fileToBase64 = (file: File): Promise<string> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => {
      const result = reader.result as string;
      // Remove data url prefix (e.g., "data:image/jpeg;base64,")
      const base64Data = result.split(',')[1];
      resolve(base64Data);
    };
    reader.onerror = (error) => reject(error);
  });
};

export const analyzeCarDamage = async (file: File): Promise<DamageEstimate> => {
  const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
  const base64Data = await fileToBase64(file);

  const prompt = `
    Analyze this image of a damaged vehicle. 
    Identify the visible damaged parts, estimate the severity of the damage for each part, and provide an estimated repair cost in KRW (Korean Won).
    Be realistic but generous with the estimate as it is better to overestimate than underestimate.
    
    Return the response in strictly valid JSON format matching this structure:
    {
      "totalCost": number (integer, sum of all parts),
      "currency": "KRW",
      "summary": "A brief, friendly summary of the overall damage in Korean language (Hangul).",
      "vehicleType": "String guessing the car type/model if possible",
      "parts": [
        {
          "name": "Part Name (in Korean)",
          "cost": number (integer estimate in KRW),
          "description": "Brief explanation of damage (in Korean)",
          "severity": "low" | "medium" | "high"
        }
      ]
    }
    
    If the image does not appear to be a car or has no visible damage, return a JSON with empty parts array and a polite message in the summary explaining that no damage was detected.
  `;

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: {
        parts: [
          {
            inlineData: {
              mimeType: file.type,
              data: base64Data,
            },
          },
          {
            text: prompt,
          },
        ],
      },
      config: {
        responseMimeType: "application/json",
        temperature: 0.4, 
      },
    });

    const responseText = response.text;
    if (!responseText) {
        throw new Error("No response from AI");
    }

    const estimate: DamageEstimate = JSON.parse(responseText);
    return estimate;

  } catch (error) {
    console.error("Error analyzing image:", error);
    throw error;
  }
};