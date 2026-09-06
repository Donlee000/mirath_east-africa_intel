from __future__ import annotations

import os

import pandas as pd


def load_to_azure_sql(tables: dict[str, pd.DataFrame]) -> None:
    try:
        from sqlalchemy import create_engine
    except ImportError as error:
        raise RuntimeError(
            "SQLAlchemy is required only for --load-sql. "
            "Install the packages in requirements.txt first."
        ) from error

    connection_string = os.getenv("AZURE_SQL_CONNECTION_STRING")
    if not connection_string:
        raise RuntimeError(
            "AZURE_SQL_CONNECTION_STRING is not set. "
            "Add it as an environment variable; never hard-code credentials."
        )

    engine = create_engine(connection_string, fast_executemany=True)
    with engine.begin() as connection:
        for table_name, frame in tables.items():
            frame.to_sql(
                table_name,
                connection,
                schema="dbo",
                if_exists="replace",
                index=False,
                chunksize=1000,
            )
