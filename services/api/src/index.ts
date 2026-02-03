import express from "express";

const app = express();
const port = process.env.PORT ? Number(process.env.PORT) : 4000;

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

app.get("/data", (_req, res) => {
  res.json({ message: "Hello from Node backend!" });
});

app.listen(port, () => {
  console.log(`API running on http://localhost:${port}`);
});
