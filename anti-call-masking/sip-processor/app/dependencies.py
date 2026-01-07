"""Dependency injection for database connections."""
import redis.asyncio as redis
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from typing import AsyncGenerator
from contextlib import asynccontextmanager

from .config import get_settings

# Redis connection pool
_redis_pool: redis.ConnectionPool | None = None


async def get_redis_pool() -> redis.ConnectionPool:
    """Get or create Redis connection pool."""
    global _redis_pool
    if _redis_pool is None:
        settings = get_settings()
        _redis_pool = redis.ConnectionPool.from_url(
            settings.redis_url,
            max_connections=settings.redis_max_connections,
            decode_responses=True
        )
    return _redis_pool


async def get_redis() -> AsyncGenerator[redis.Redis, None]:
    """Get Redis connection from pool."""
    pool = await get_redis_pool()
    client = redis.Redis(connection_pool=pool)
    try:
        yield client
    finally:
        await client.aclose()


# PostgreSQL engine and session
_pg_engine = None
_pg_session_factory = None


def get_pg_engine():
    """Get or create PostgreSQL async engine."""
    global _pg_engine
    if _pg_engine is None:
        settings = get_settings()
        _pg_engine = create_async_engine(
            settings.postgres_url,
            pool_size=settings.postgres_pool_size,
            echo=settings.debug
        )
    return _pg_engine


def get_pg_session_factory():
    """Get or create PostgreSQL session factory."""
    global _pg_session_factory
    if _pg_session_factory is None:
        engine = get_pg_engine()
        _pg_session_factory = async_sessionmaker(
            engine, 
            class_=AsyncSession, 
            expire_on_commit=False
        )
    return _pg_session_factory


async def get_postgres() -> AsyncGenerator[AsyncSession, None]:
    """Get PostgreSQL session."""
    session_factory = get_pg_session_factory()
    async with session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


@asynccontextmanager
async def lifespan_context():
    """Context manager for application lifespan."""
    # Startup
    await get_redis_pool()
    get_pg_engine()
    
    yield
    
    # Shutdown
    global _redis_pool, _pg_engine
    if _redis_pool:
        await _redis_pool.disconnect()
        _redis_pool = None
    if _pg_engine:
        await _pg_engine.dispose()
        _pg_engine = None
