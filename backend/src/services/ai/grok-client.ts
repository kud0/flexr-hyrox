import env from '../../config/env';
import logger from '../../utils/logger';

export interface GrokChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface GrokChatCompletionRequest {
  model: string;
  messages: GrokChatMessage[];
  temperature?: number;
  max_tokens?: number;
  stream?: boolean;
}

export interface GrokChatCompletionResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: Array<{
    index: number;
    message: {
      role: string;
      content: string;
    };
    finish_reason: string;
  }>;
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

export class GrokClient {
  private apiKey: string;
  private apiUrl: string;
  private model: string;

  constructor() {
    this.apiKey = env.GROK_API_KEY;
    this.apiUrl = env.GROK_API_URL;
    this.model = env.GROK_MODEL;
  }

  /**
   * Create a chat completion using Grok API
   */
  async createChatCompletion(
    messages: GrokChatMessage[],
    options: {
      temperature?: number;
      maxTokens?: number;
      model?: string;
    } = {}
  ): Promise<GrokChatCompletionResponse> {
    const requestBody: GrokChatCompletionRequest = {
      model: options.model || this.model,
      messages,
      temperature: options.temperature ?? 0.7,
      max_tokens: options.maxTokens ?? 2000,
      stream: false,
    };

    try {
      logger.debug('Grok API request:', { messages: messages.length, model: requestBody.model });

      const response = await fetch(`${this.apiUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        const errorText = await response.text();
        logger.error('Grok API error:', {
          status: response.status,
          statusText: response.statusText,
          error: errorText,
        });
        throw new Error(`Grok API request failed: ${response.status} ${response.statusText}`);
      }

      const data: GrokChatCompletionResponse = await response.json();

      logger.debug('Grok API response:', {
        id: data.id,
        model: data.model,
        usage: data.usage,
      });

      return data;
    } catch (error) {
      logger.error('Grok API request failed:', error);
      throw new Error('Failed to communicate with Grok AI. Please try again later.');
    }
  }

  /**
   * Extract content from Grok response
   */
  extractContent(response: GrokChatCompletionResponse): string {
    if (!response.choices || response.choices.length === 0) {
      throw new Error('No choices in Grok response');
    }

    const content = response.choices[0].message.content;
    if (!content) {
      throw new Error('Empty content in Grok response');
    }

    return content.trim();
  }

  /**
   * Parse JSON response from Grok, handling markdown code blocks
   */
  parseJsonResponse<T = any>(response: GrokChatCompletionResponse): T {
    const content = this.extractContent(response);

    // Remove markdown code blocks if present
    let jsonStr = content;
    if (content.includes('```json')) {
      const match = content.match(/```json\s*([\s\S]*?)\s*```/);
      if (match) {
        jsonStr = match[1];
      }
    } else if (content.includes('```')) {
      const match = content.match(/```\s*([\s\S]*?)\s*```/);
      if (match) {
        jsonStr = match[1];
      }
    }

    try {
      return JSON.parse(jsonStr);
    } catch (error) {
      logger.error('Failed to parse Grok JSON response:', { content, error });
      throw new Error('Invalid JSON response from Grok AI');
    }
  }

  /**
   * Rate limit handling - implement exponential backoff
   */
  private async handleRateLimit(retryAfter?: number): Promise<void> {
    const waitTime = retryAfter ? retryAfter * 1000 : 5000; // Default 5 seconds
    logger.warn(`Rate limited by Grok API. Waiting ${waitTime}ms before retry...`);
    await new Promise((resolve) => setTimeout(resolve, waitTime));
  }
}

// Export singleton instance
export const grokClient = new GrokClient();
export default grokClient;
