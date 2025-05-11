from fastapi import FastAPI, Request, Form, Depends, HTTPException, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from pydantic import BaseModel
from typing import Tuple
import secrets
import json
import os

app = FastAPI()

# Setup for templates and optional static files
templates = Jinja2Templates(directory="templates")
app.mount("/static", StaticFiles(directory="static"), name="static")
app.mount("/stream", StaticFiles(directory="stream"), name="stream")

CONFIG_FILE = "config.json"

# Basic HTTP authentication setup
security = HTTPBasic()

USERNAME = "admin"
PASSWORD = "admin"

def check_auth(credentials: HTTPBasicCredentials = Depends(security)):
    correct_username = secrets.compare_digest(credentials.username, USERNAME)
    correct_password = secrets.compare_digest(credentials.password, PASSWORD)
    if not (correct_username and correct_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Basic"},
        )
    return credentials.username


class Config(BaseModel):
    framerate: int					# camera framerate
    resolution: Tuple[int, int]		# camera resolution
    env_sensor_interval: int		# sensor recording interval in minutes

# Load config from file or use default
def load_config() -> Config:
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            data = json.load(f)
            return Config(**data)
    else:
        return Config(framerate=15, resolution=(640, 480), env_sensor_interval=60)

def save_config(cfg: Config):
    with open(CONFIG_FILE, "w") as f:
        json.dump(cfg.dict(), f)

config = load_config()

@app.get("/", response_class=HTMLResponse)
async def video_page(request: Request):
    return templates.TemplateResponse("index.html", {
		"request": request
    })

@app.get("/config", response_model=Config)
def get_config():
    return config

@app.get("/set-config", response_class=HTMLResponse)
def set_config_form(request: Request, username: str = Depends(check_auth)):
    return templates.TemplateResponse("set_config.html", {
        "request": request,
        "config": config
    })

@app.post("/set-config")
async def update_config(
    framerate: int = Form(...),
    width: int = Form(...),
    height: int = Form(...),
    env_sensor_interval: int = Form(...),
    username: str = Depends(check_auth)
):
    global config
    config = Config(
        framerate=framerate,
        resolution=(width, height),
        env_sensor_interval=env_sensor_interval
    )
    save_config(config)
    return RedirectResponse(url="/set-config", status_code=303)
