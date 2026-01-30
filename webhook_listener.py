from flask import Flask, request, abort
import hmac
import hashlib
import subprocess
import os
from dotenv import load_dotenv

app = Flask(__name__)

load_dotenv()

DEPLOY_SECRET = os.getenv('DEPLOY_SECRET')
DEPLOY_SCRIPT = '/root/code-agent-global/code-agent-deploy/deploy.sh'

if not DEPLOY_SECRET:
    raise RuntimeError("DEPLOY_SECRET must be set in .env")

DEPLOY_SECRET = DEPLOY_SECRET.encode()


def verify_signature(data, signature):
    if not signature:
        return False
    try:
        sha_name, signature = signature.split('=')
    except Exception:
        return False
    if sha_name != 'sha256':
        return False
    mac = hmac.new(DEPLOY_SECRET, msg=data, digestmod=hashlib.sha256)
    return hmac.compare_digest(mac.hexdigest(), signature)


@app.route('/deploy', methods=['POST'])
def deploy():
    signature = request.headers.get('X-Hub-Signature-256')
    if not signature:
        abort(400, 'No X-Hub-Signature-256 header')

    data = request.data
    if not verify_signature(data, signature):
        abort(403, 'Invalid signature')

    event = request.headers.get('X-GitHub-Event')
    if event != 'push':
        return 'Not a push event', 200

    payload = request.json
    if not payload:
        abort(400, 'No JSON payload')

    ref = payload.get('ref')
    if ref != 'refs/heads/main':
        return 'Not main branch push', 200

    try:
        result = subprocess.run([DEPLOY_SCRIPT], check=True, env=os.environ, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        return f'Deploy failed:\n{e.stderr}', 500

    return f'Deploy successful:\n{result.stdout}', 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
