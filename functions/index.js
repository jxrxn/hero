const functions = require("firebase-functions");

exports.imageProxy = functions.https.onRequest(async (req, res) => {
  try {
    const raw = req.query.url;
    if (!raw || typeof raw !== "string") {
      res.status(400).json({error: "Missing ?url="});
      return;
    }

    // CORS (tillåt web-app)
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET,OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    const url = decodeURIComponent(raw);

    // Basic safety: bara http/https
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      res.status(400).json({error: "Invalid url scheme"});
      return;
    }

    const r = await fetch(url, {
      method: "GET",
      redirect: "follow",
      // En del bild-CDNs gillar en User-Agent
      headers: {"User-Agent": "HeroDex3000/1.0"},
    });

    if (!r.ok) {
      res.status(502).json({error: `Upstream ${r.status}`});
      return;
    }

    const contentType = r.headers.get("content-type") || "";
    if (!contentType.startsWith("image/")) {
      // Om du råkar proxya API-JSON igen -> blocka
      res.status(415).json({
        error: "Upstream is not an image",
        contentType,
      });
      return;
    }

    const buf = Buffer.from(await r.arrayBuffer());

    res.set("Content-Type", contentType);
    res.set("Cache-Control", "public, max-age=86400"); // 24h cache
    res.status(200).send(buf);
  } catch (e) {
    res.status(500).json({error: "Proxy failed"});
  }
});
