const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json());

// Endpoint for streaming LLM responses
app.post('/api/chat', async (req, res) => {
  const { prompt, systemPrompt } = req.body;

  if (!prompt) {
    return res.status(400).json({ error: 'Prompt is required' });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error('ERROR: GEMINI_API_KEY is not defined in server env file.');
    return res.status(500).json({ error: 'Gemini API key is not configured on the proxy server.' });
  }

  try {
    // Set headers for standard chunked HTTP response streaming
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.setHeader('Transfer-Encoding', 'chunked');

    console.log(`[Proxy] Initiating stream request for prompt: "${prompt.substring(0, 50)}..."`);

    // Initialize Gemini SDK
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ 
      model: 'gemini-1.5-flash',
      // If a system prompt is provided, pass it as a config option
      ...(systemPrompt ? { systemInstruction: systemPrompt } : {})
    });

    // Call Gemini API and stream content back to client
    const result = await model.generateContentStream({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
    });

    for await (const chunk of result.stream) {
      const chunkText = chunk.text();
      res.write(chunkText);
    }

    res.end();
    console.log('[Proxy] Stream request completed successfully.');
  } catch (error) {
    console.error('[Proxy ERROR]:', error);
    
    // If headers haven't been sent yet, send a JSON error. Otherwise, end the chunked response.
    if (!res.headersSent) {
      res.status(500).json({ error: 'Failed to generate LLM stream response: ' + error.message });
    } else {
      res.write('\n[Proxy ERROR: Stream interrupted during generation]');
      res.end();
    }
  }
});

app.listen(PORT, () => {
  console.log(`==================================================`);
  console.log(`LLM Proxy Server running on http://localhost:${PORT}`);
  console.log(`Endpoints available: POST /api/chat`);
  console.log(`==================================================`);
});
