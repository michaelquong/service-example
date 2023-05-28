from flask import Flask
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()
migrate = Migrate()

def register_models(app: Flask) -> None:
    """Initiate db SQLalchemy instance with configuration with Flask app.
    Also initiate migration scripts to reflect model changes.
    """
    username = app.config["MYSQL_DATABASE_USER"]
    password = app.config["MYSQL_DATABASE_PASSWORD"]
    server = f'{app.config["MYSQL_DATABASE_HOST"]}:{app.config["MYSQL_DATABASE_PORT"]}'
    database = app.config["MYSQL_DATABASE_DB"]
    app.config["SQLALCHEMY_DATABASE_URI"] = f"mysql+pymysql://{username}:{password}@{server}/{database}"
    
    db.init_app(app)
    
    migrate.init_app(app, db)
