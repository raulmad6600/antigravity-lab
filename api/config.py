from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Antigravity-Lab"
    debug: bool = True
    ollama_model: str = "llama3"
    ollama_base_url: str = "http://localhost:11434"
    max_iterations: int = 3
    host: str = "0.0.0.0"
    port: int = 8000

    class Config:
        env_file = ".env"


settings = Settings()