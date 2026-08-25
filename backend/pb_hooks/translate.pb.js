routerAdd("POST", "/api/translate", (e) => {
    const info = e.requestInfo(); // v0.23+
    
    // Auth check
    if (!info.auth) {
        throw new UnauthorizedError("Authentication required.");
    }

    const userId = info.auth.id;
    let body = {};
    try {
       // try v0.23 body reading
       const rawBody = $apis.requestInfo(e).data;
       body = rawBody;
    } catch(err) {
       body = info.body;
    }

    const { rawText, glossary, previousSummaries, provider } = body;
    
    if (!rawText) {
        throw new BadRequestError("rawText is required.");
    }

    // Cost logic
    const tokensUsed = rawText.length; // rough estimate for now
    const cost = tokensUsed * 0.001; // dummy cost

    // Check credits
    const user = $app.findRecordById("users", userId);
    const credits = user.get("credits") || 0;
    if (credits < cost) {
        throw new BadRequestError("Insufficient credits.");
    }

    // Dummy LLM response for now (to test hook)
    const translatedText = "Translated: " + rawText;
    const summary = "Dummy summary";
    
    // Deduct credits
    user.set("credits", credits - cost);
    $app.save(user);

    // Log to apiLogs
    const logCollection = $app.findCollectionByNameOrId("apiLogs");
    const logRecord = new Record(logCollection);
    logRecord.set("user", userId);
    logRecord.set("tokensUsed", tokensUsed);
    logRecord.set("cost", cost);
    logRecord.set("provider", provider || "dummy");
    logRecord.set("status", "success");
    $app.save(logRecord);

    return e.json(200, {
        translatedText: translatedText,
        summary: summary,
        newCharacters: [],
        newRelations: []
    });
});
