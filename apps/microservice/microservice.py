# microservice.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/api/v1/secure-data")
async def get_secure_data():
    return {
        "status": "success",
        "data": "This is protected data from the backend microservice!"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("microservice:app", port=8001, reload=True)