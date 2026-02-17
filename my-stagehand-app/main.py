import asyncio
import os

from dotenv import load_dotenv
from pydantic import BaseModel
from stagehand import AsyncStagehand

load_dotenv()


class StagehandDescription(BaseModel):
    answer: str


class ModelInfo(BaseModel):
    name: str
    provider: str = ""
    accuracy: float = 0.0


async def main():
    """Basic Stagehand browser automation example."""

    client = AsyncStagehand(
        browserbase_api_key=os.getenv("BROWSERBASE_API_KEY"),
        browserbase_project_id=os.getenv("BROWSERBASE_PROJECT_ID"),
        model_api_key=os.getenv("MODEL_API_KEY"),
    )

    # Start a Stagehand session
    session = await client.sessions.create(model_name="google/gemini-3-flash-preview")
    print(f"Session started: {session.id}")
    print(f"View live: https://www.browserbase.com/sessions/{session.id}")

    try:
        # Navigate to a webpage
        await session.navigate(url="https://docs.stagehand.dev")

        # Extract data using Stagehand AI
        result = await session.extract(
            instruction="In a few words, what is Stagehand?",
            schema=StagehandDescription.model_json_schema(),
        )
        print(f"Extracted: {result.data.result}")

        # Perform AI-powered action
        await session.act(input="click on models")

        # Observe elements on the page
        observe_response = await session.observe(
            instruction="find the graph with the list of most accurate models",
        )
        print(f"Found {len(observe_response.data.result)} elements")

        # Extract structured data
        result = await session.extract(
            instruction="the most accurate model",
            schema=ModelInfo.model_json_schema(),
        )
        print(f"Most accurate model: {result.data.result}")

    finally:
        await session.end()
        print("Session ended")


if __name__ == "__main__":
    asyncio.run(main())
