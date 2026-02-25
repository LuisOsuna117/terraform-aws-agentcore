from strands import Agent
from bedrock_agentcore.runtime import BedrockAgentCoreApp

app = BedrockAgentCoreApp()
agent = Agent(system_prompt="You are a helpful assistant. Answer questions clearly and concisely.")


@app.entrypoint
async def invoke(payload=None):
    query = payload.get("prompt", "Hello!") if payload else "Hello!"
    response = agent(query)
    return {"response": response.message["content"][0]["text"]}


if __name__ == "__main__":
    app.run()
