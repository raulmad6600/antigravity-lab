import httpx
from .base import BaseLLM


class OllamaAdapter(BaseLLM):
    def __init__(self, model: str = "llama3"):
        self.model = model
        self.base_url = "http://localhost:11434"

    async def generate(self, prompt: str) -> str:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=120
            )
            response.raise_for_status()
            return response.json()["response"]