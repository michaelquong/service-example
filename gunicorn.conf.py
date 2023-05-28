# Load environment configuration
import os
from dotenv import load_dotenv

envfile = os.path.join(os.getcwd(), ".env")
if os.path.exists(envfile):
    load_dotenv(envfile)