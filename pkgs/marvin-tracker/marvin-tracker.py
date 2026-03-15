# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "fastapi",
#     "uvicorn",
#     "aiomqtt",
# ]
# ///
import asyncio
import hashlib
import hmac
import json
import os
import time
from base64 import b64decode
from contextlib import asynccontextmanager

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware

MQTT_HOST = os.environ.get("MQTT_HOST", "localhost")
MQTT_USER = os.environ.get("MQTT_USER", "guest")
MQTT_PASSWORD = os.environ.get("MQTT_PASSWORD", "guest")
TOPIC = os.environ.get("TOPIC", "yorick/marvin/tracking")
API_HASH = os.environ.get(
    "API_HASH",
    "z6mzC2TGdVCRuFE+oCrwj1GCHyP6OzYcPKZDiO/yLdqpmChC6S7ijCEUSY5gtqhpXhtYeDRyBjNeVJ/0Se4jQQ==",
)
PORT = int(os.environ.get("PORT", "3000"))
HOST = os.environ.get("HOST", "::")

currently_tracking: dict = {}
mqtt_client = None


def check_key(password: str | None) -> bool:
    if not isinstance(password, str):
        return False
    h = hashlib.blake2b()
    h.update(b"O9yn_qX_jz68H-B6BrkEzRGAWfInzgeOmsCajTJVwcw=")
    h.update(password.encode())
    h.update(b"LHVV58vOGu7pKSV_Ofmes2joHCal6-F9UuhNLvOK7HM=")
    return hmac.compare_digest(h.digest(), b64decode(API_HASH))


async def set_track(track: dict):
    global currently_tracking
    track["time"] = int(time.time() * 1000)
    currently_tracking = track
    if mqtt_client is not None:
        await mqtt_client.publish(TOPIC, json.dumps(track).encode(), retain=True)


async def mqtt_loop():
    global currently_tracking, mqtt_client
    import aiomqtt

    while True:
        try:
            async with aiomqtt.Client(
                MQTT_HOST, username=MQTT_USER, password=MQTT_PASSWORD
            ) as client:
                mqtt_client = client
                print("mqtt connected")
                await client.subscribe(TOPIC)
                async for message in client.messages:
                    if str(message.topic) == TOPIC:
                        try:
                            currently_tracking = json.loads(message.payload)
                        except Exception:
                            print(f"unable to parse message: {message.payload!r}")
        except Exception as e:
            mqtt_client = None
            print(f"mqtt disconnected: {e}, reconnecting in 5s")
            await asyncio.sleep(5)


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(mqtt_loop())
    yield
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST"],
    allow_headers=["Content-Type", "X-Marv-Key"],
)


def require_auth(x_marv_key: str | None = Header(None)):
    if not check_key(x_marv_key):
        raise HTTPException(status_code=403, detail="auth required")


@app.post("/startTracking")
async def start_tracking(request: Request, x_marv_key: str | None = Header(None)):
    require_auth(x_marv_key)
    task = await request.json()
    await set_track({"task": task, "started": True})


@app.post("/stopTracking")
async def stop_tracking(request: Request, x_marv_key: str | None = Header(None)):
    require_auth(x_marv_key)
    task = await request.json()
    if task.get("done"):
        await set_track({})
    else:
        await set_track({"task": task, "started": False})


@app.post("/markDoneTask")
async def mark_done_task(request: Request, x_marv_key: str | None = Header(None)):
    require_auth(x_marv_key)
    task = await request.json()
    tracking_task = currently_tracking.get("task")
    if tracking_task and task.get("_id") == tracking_task.get("_id"):
        await set_track({})


@app.post("/deleteTask")
async def delete_task(request: Request, x_marv_key: str | None = Header(None)):
    require_auth(x_marv_key)
    task = await request.json()
    tracking_task = currently_tracking.get("task")
    if tracking_task and task.get("_id") == tracking_task.get("_id"):
        await set_track({})


@app.post("/editTask")
async def edit_task(request: Request, x_marv_key: str | None = Header(None)):
    require_auth(x_marv_key)
    task = await request.json()
    tracking_task = currently_tracking.get("task")
    if tracking_task and task.get("_id") == tracking_task.get("_id"):
        await set_track({"task": task, "started": currently_tracking.get("started")})


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host=HOST, port=PORT)
