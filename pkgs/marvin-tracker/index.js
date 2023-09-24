#!/usr/bin/env node
import http from 'node:http';
import * as mqtt from "mqtt"
import { createHash, timingSafeEqual } from "node:crypto"

const settings = {
    mqtt_host: process.env.MQTT_HOST || "localhost",
    mqtt_username: process.env.MQTT_USER || "guest",
    mqtt_password: process.env.MQTT_PASSWORD || "guest",
    topic: process.env.TOPIC || "yorick/marvin/tracking",
    api_hash: process.env.API_HASH || "z6mzC2TGdVCRuFE+oCrwj1GCHyP6OzYcPKZDiO/yLdqpmChC6S7ijCEUSY5gtqhpXhtYeDRyBjNeVJ/0Se4jQQ==",
    listen_port: +process.env.PORT || 3000,
    listen_host: process.env.HOST || "::",
}

const client = mqtt.connect(`mqtt://${settings.mqtt_host}`, {
    username: settings.mqtt_username,
    password: settings.mqtt_password
});

let currently_tracking = {}

client.subscribe(settings.topic)

client.on("connect", () => {
    console.log("mqtt connected")
})
client.on("message", (topic, message) => {
    if (topic == settings.topic) {
        try {
            currently_tracking = JSON.parse(message)
        } catch(e) {
            console.warn("unable to parse message", msg)
        }
    }
})

function checkKey(password) {
    if (typeof password !== "string") return false
    // would be nice if this took salt
    const h = createHash("blake2b512")
    // salt
    h.update("O9yn_qX_jz68H-B6BrkEzRGAWfInzgeOmsCajTJVwcw=")
    h.update(password)
    // more salt
    h.update("LHVV58vOGu7pKSV_Ofmes2joHCal6-F9UuhNLvOK7HM=")
    const d = h.digest()
    return timingSafeEqual(Buffer.from(settings.api_hash, "base64"), d)
}

async function waitForJSON(req, max_size) {
  return new Promise((resolve, reject) => {
    let body = [];
    let accumulatedSize = 0;

    req.on('data', (chunk) => {
      accumulatedSize += chunk.length;

      if (accumulatedSize > max_size) {
        reject({statusCode: 413, message: 'Payload too large'});
        req.connection.destroy();
      } else {
        body.push(chunk);
      }
    });

    req.on('end', () => {
      try {
        const parsedBody = JSON.parse(Buffer.concat(body).toString());
        resolve(parsedBody);
      } catch (e) {
        reject({statusCode: 400, message: 'Bad Request'});
      }
    });

    req.on('error', (err) => {
      reject({statusCode: 500, message: 'Internal Server Error'});
    });
  });
}

const supported_urls = ["startTracking", "stopTracking", "markDoneTask", "deleteTask", "editTask"]

async function setTrack(track) {
    track.time = Date.now()
    currently_tracking = track
    await client.publishAsync(settings.topic, JSON.stringify(track), {
        retain: true
    })
}

const endpoints = {
    async startTracking(task) {
        await setTrack({ task, started: true })
    },
    async stopTracking(task) {
        if (task.done) {
            await setTrack({})
        } else {
            await setTrack({ task, started: false })
        }
    },
    async markDoneTask(task) {
        if (task._id == currently_tracking.task?._id)
            await setTrack({})
    },
    async deleteTask(task) {
        if (task._id == currently_tracking.task?._id)
            await setTrack({})
    },
    async editTask(task) {
        if (task._id == currently_tracking.task?._id)
            await setTrack({ task, started: currently_tracking.started })
    }
}

// todo: check headers
async function handle(req, res) {
    console.log(req.method, req.url)
    if (endpoints[req.url.slice(1)]) {
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'POST');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Marv-Key');
        if (req.method == "OPTIONS") {}
        else if (req.method == "POST") {
            if (!checkKey(req.headers["x-marv-key"])) {
                throw { statusCode: 403, message: "auth required" }
            }
            const body = await waitForJSON(req, 1024 * 512) // 512 kb
            await endpoints[req.url.slice(1)](body)
            res.end()
        } else {
            throw { statusCode: 405, message: "Method not supported" }
        }
        res.end()
    } else {
        throw { statusCode: 404, message: "Unknown endpoint" }
    }
}

const server = http.createServer(async (req, res) => {
    try {
      await handle(req, res);
    } catch (err) {
        console.warn("error in request", err)
      res.writeHead(err.statusCode || 500, {'Content-Type': 'text/plain'}).end(err.message || 'Internal Server Error');
    }
})


server.listen(settings.listen_port, settings.listen_host, () => {
    console.log(`Server running on http://${settings.listen_host}:${settings.listen_port}/`);
});
