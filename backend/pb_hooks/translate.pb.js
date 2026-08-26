routerAdd("POST", "/api/translate", (e) => {
  const info = e.requestInfo();

  // ---------------------------------------------------------
  // Auth check
  // ---------------------------------------------------------

  if (!info.auth) {
    throw new UnauthorizedError("Authentication required.");
  }

  const userId = info.auth.id;

  // ---------------------------------------------------------
  // Read request body
  // ---------------------------------------------------------

  let body = {};

  try {
    body = $apis.requestInfo(e).data;
  } catch (err) {
    body = info.body || {};
  }

  const { rawText, glossary, previousSummaries, targetLanguage } = body;

  const lang = targetLanguage || "Vietnamese";

  if (!rawText || typeof rawText !== "string") {
    throw new BadRequestError("rawText is required.");
  }

  // ---------------------------------------------------------
  // Get AI settings
  // ---------------------------------------------------------

  let aiUrl = "https://openrouter.ai/api/v1/chat/completions";
  let token = "";
  let modelName = "deepseek/deepseek-v4-flash";

  try {
    const settingsRecords = $app.findAllRecords("settings");

    if (settingsRecords && settingsRecords.length > 0) {
      const settings = settingsRecords[0];

      aiUrl = settings.get("ai_url") || aiUrl;
      token = settings.get("token") || settings.get("apiKey") || "";

      modelName = settings.get("provider") || modelName;
    }
  } catch (err) {
    console.log("Failed to load settings:", err);
  }

  if (!token) {
    throw new BadRequestError("AI token not configured in settings.");
  }

  // ---------------------------------------------------------
  // Build previous chapter summaries
  // ---------------------------------------------------------

  let previousContext = "None";

  if (Array.isArray(previousSummaries) && previousSummaries.length > 0) {
    previousContext = previousSummaries
      .filter((item) => typeof item === "string" && item.trim())
      .join("\n");
  }

  // ---------------------------------------------------------
  // Build glossary
  // ---------------------------------------------------------

  let glossaryContext = "None";

  if (Array.isArray(glossary) && glossary.length > 0) {
    glossaryContext = glossary
      .map((g) => {
        const originalName = g.originalName || g.source || "";

        const translatedName = g.translatedName || g.target || "";

        const role = g.role || "";
        const pronouns = g.pronouns || g.pronoun || "";

        const description = g.description || "";

        let line = `- ${originalName}`;

        if (translatedName) {
          line += ` -> ${translatedName}`;
        }

        const metadata = [];

        if (role) {
          metadata.push(`Role: ${role}`);
        }

        if (pronouns) {
          metadata.push(`Pronoun: ${pronouns}`);
        }

        if (description) {
          metadata.push(`Description: ${description}`);
        }

        if (metadata.length > 0) {
          line += ` | ${metadata.join(" | ")}`;
        }

        return line;
      })
      .join("\n");
  }

  // ---------------------------------------------------------
  // System prompt
  //
  // Keep system prompt short and focused on output format.
  // This matches the DeepSeek payload that works reliably.
  // ---------------------------------------------------------

  const systemPrompt = `
You MUST return ONLY valid JSON.

The JSON must have exactly the following structure:

{
  "translatedText": "string",
  "summary": "string",
  "newCharacters": [
    {
      "name": "string",
      "targetName": "string",
      "role": "string",
      "pronoun": "string",
      "description": "string"
    }
  ],
  "newRelations": [
    {
      "source": "string",
      "target": "string",
      "label": "string",
      "type": "friendly|hostile|unknown"
    }
  ]
}

Do not wrap the JSON in markdown fences.
Do not output explanations before or after the JSON.
`.trim();

  // ---------------------------------------------------------
  // Translation prompt
  // ---------------------------------------------------------

  const userPrompt = `
[ROLE]

You are a professional literary translator specializing in Chinese fiction novels, especially xianxia, wuxia, cultivation, mythology, martial arts fantasy, and related genres.

[TASK]

Translate the chapter below from Chinese into ${lang}.

The translation must be written in ${lang}.

Do NOT return the original Chinese text instead of translating it.

Translate faithfully while producing natural literary prose appropriate for a novel.

[RULES]

- Preserve the original meaning.
- Preserve character intent.
- Preserve narrative tone and atmosphere.
- Preserve emotional nuance.
- Preserve character personalities.
- Preserve important world-building details.
- Preserve cultivation levels, techniques, sects, titles, artifacts, locations, and other important terminology.
- Use the provided glossary consistently.
- Keep character names consistent with the glossary.
- Do not invent information that does not exist in the source.
- Do not omit meaningful information.
- Do not summarize the chapter inside translatedText.
- translatedText must contain the full translated chapter.
- If the source contains a chapter title, translate it and place it naturally at the beginning.
- Use natural ${lang} dialogue and narration.
- Character forms of address and pronouns must follow their relationships, identities, hierarchy, age, and context.
- Fictional mythology, supernatural abilities, martial arts, violence, cultivation, or other fictional elements should simply be translated as fictional narrative content.

[PREVIOUS CHAPTER SUMMARIES]

${previousContext}

[KNOWN CHARACTERS GLOSSARY]

${glossaryContext}

[OUTPUT FIELD RULES]

translatedText:
- Full translation into ${lang}.
- Must NOT be Chinese unless a Chinese term genuinely needs to remain untranslated.

summary:
- A concise summary of this chapter.
- Write the summary in ${lang}.

newCharacters:
- Include ONLY characters appearing in this chapter that are NOT already present in KNOWN CHARACTERS GLOSSARY.
- name: original Chinese character name.
- targetName: translated/localized name used in ${lang}.
- role: concise role in the story, written in ${lang}.
- pronoun: appropriate pronoun/form of reference in ${lang}.
- description: concise description based ONLY on information available so far, written in ${lang}.
- If there are no new characters, return [].

newRelations:
- Extract useful relationships introduced or revealed in this chapter.
- source and target should identify the characters consistently.
- label must be written in ${lang}.
- type must be exactly one of:
  "friendly"
  "hostile"
  "unknown"
- If there are no meaningful new relationships, return [].

[CRITICAL LANGUAGE REQUIREMENT]

The target language is ${lang}.

translatedText, summary, role, pronoun, description, and relationship label MUST be written in ${lang}.

Chinese is allowed in newCharacters.name because that field stores the original character name.

[CHAPTER TEXT TO TRANSLATE]

${rawText}
`.trim();

  // ---------------------------------------------------------
  // Build OpenRouter request
  // ---------------------------------------------------------

  const payload = {
    model: modelName,

    provider: {
      sort: "latency",
    },

    reasoning: {
      enabled: false,
    },

    messages: [
      {
        role: "system",
        content: systemPrompt,
      },
      {
        role: "user",
        content: userPrompt,
      },
    ],

    response_format: {
      type: "json_object",
    },

    temperature: 0.3,
  };

  // ---------------------------------------------------------
  // Make API request
  // ---------------------------------------------------------

  console.log("=== AI REQUEST ===");
  console.log("URL:", aiUrl);
  console.log("Payload:", JSON.stringify(payload, null, 2));

  const res = $http.send({
    url: aiUrl,
    method: "POST",

    body: JSON.stringify(payload),

    headers: {
      Authorization: "Bearer " + token,
      "Content-Type": "application/json",
      "HTTP-Referer": "http://localhost:5173",
      "X-Title": "Novel Translator",
    },

    timeout: 300,
  });

  // ---------------------------------------------------------
  // Log raw response
  // ---------------------------------------------------------

  console.log("=== AI RESPONSE ===");
  console.log("Status:", res.statusCode);
  console.log("Raw Response:", res.raw);

  // ---------------------------------------------------------
  // Provider error
  // ---------------------------------------------------------

  if (res.statusCode !== 200) {
    let errData = "";

    try {
      errData = JSON.stringify(res.json);
    } catch (err) {
      errData = res.raw;
    }

    throw new BadRequestError("AI Provider Error: " + errData);
  }

  // ---------------------------------------------------------
  // Parse OpenRouter response
  // ---------------------------------------------------------

  let aiResData;

  try {
    aiResData = res.json;

    if (!aiResData || !aiResData.choices) {
      aiResData = JSON.parse(res.raw.trim());
    }
  } catch (err) {
    console.log("Failed to parse provider response:", err);

    throw new BadRequestError("AI Provider Error: Invalid JSON response");
  }

  if (
    !Array.isArray(aiResData.choices) ||
    aiResData.choices.length === 0 ||
    !aiResData.choices[0] ||
    !aiResData.choices[0].message
  ) {
    throw new BadRequestError("AI Provider Error: Empty AI response");
  }

  // ---------------------------------------------------------
  // Extract content
  // ---------------------------------------------------------

  const content = aiResData.choices[0].message.content || "";

  if (!content) {
    throw new BadRequestError("AI Provider Error: Empty response content");
  }

  let translatedText = "";
  let summary = "";
  let newCharacters = [];
  let newRelations = [];

  // ---------------------------------------------------------
  // Parse structured JSON
  // ---------------------------------------------------------

  try {
    let cleanContent = content.trim();

    // Defensive cleanup
    cleanContent = cleanContent
      .replace(/^```json\s*/i, "")
      .replace(/^```\s*/, "")
      .replace(/\s*```$/, "")
      .trim();

    const parsed = JSON.parse(cleanContent);

    translatedText =
      typeof parsed.translatedText === "string" ? parsed.translatedText : "";

    summary = typeof parsed.summary === "string" ? parsed.summary : "";

    newCharacters = Array.isArray(parsed.newCharacters)
      ? parsed.newCharacters
      : [];

    newRelations = Array.isArray(parsed.newRelations)
      ? parsed.newRelations
      : [];
  } catch (err) {
    console.log("Failed to parse AI output JSON:", err);

    console.log("AI content:", content);

    // Fallback
    translatedText = content;
    summary = "";
    newCharacters = [];
    newRelations = [];
  }

  // ---------------------------------------------------------
  // Basic output validation
  // ---------------------------------------------------------

  if (!translatedText) {
    throw new BadRequestError("AI Provider Error: translatedText is empty");
  }

  // ---------------------------------------------------------
  // Usage
  // ---------------------------------------------------------

  const usage = aiResData.usage || {};

  const promptTokens = usage.prompt_tokens || 0;

  const completionTokens = usage.completion_tokens || 0;

  const tokensUsed =
    usage.total_tokens || promptTokens + completionTokens || rawText.length;

  // ---------------------------------------------------------
  // Temporary credit conversion
  // ---------------------------------------------------------

  const cost = tokensUsed * 0.001;

  // ---------------------------------------------------------
  // Check & deduct credits
  // ---------------------------------------------------------

  const user = $app.findRecordById("users", userId);

  const credits = Number(user.get("credits")) || 0;

  if (credits < cost) {
    throw new BadRequestError("Insufficient credits.");
  }

  user.set("credits", credits - cost);

  $app.save(user);

  // ---------------------------------------------------------
  // Log usage
  // ---------------------------------------------------------

  try {
    const logCollection = $app.findCollectionByNameOrId("apiLogs");

    const logRecord = new Record(logCollection);

    logRecord.set("user", userId);

    logRecord.set("tokensUsed", tokensUsed);

    logRecord.set("cost", cost);

    logRecord.set("provider", payload.model);

    logRecord.set("status", "success");

    $app.save(logRecord);
  } catch (err) {
    console.log("Failed to log API usage:", err);
  }

  // ---------------------------------------------------------
  // Response
  // ---------------------------------------------------------

  return e.json(200, {
    translatedText,
    summary,
    newCharacters,
    newRelations,
  });
});
