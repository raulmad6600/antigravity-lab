from pydantic import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Antigravity-Lab"
    debug: bool = True
    ollama_model: str = "llama3"
    max_iterations: int = 3

    class Config:
        env_file = ".env"


settings = Settings()