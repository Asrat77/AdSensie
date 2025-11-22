#!/usr/bin/env python3
"""
Fetch Single Channel Data
Usage: python3 fetch_single_channel.py <username>
Outputs JSON to stdout
"""

import os
import sys
import json
import asyncio
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
from telethon import TelegramClient
from telethon.tl.functions.channels import GetFullChannelRequest
from telethon.tl.types import Channel

# Load environment variables
load_dotenv()

API_ID = int(os.getenv('TELEGRAM_API_ID'))
API_HASH = os.getenv('TELEGRAM_API_HASH')
SESSION_NAME = 'adsensie_session'

class SingleChannelFetcher:
    def __init__(self):
        self.client = TelegramClient(SESSION_NAME, API_ID, API_HASH)
    
    async def connect(self):
        await self.client.start()
    
    async def fetch(self, username):
        try:
            username = username.lstrip('@')
            entity = await self.client.get_entity(username)
            
            if not isinstance(entity, Channel):
                return {"error": "Not a channel"}
            
            # Get full info
            full_channel = await self.client(GetFullChannelRequest(entity))
            
            channel_data = {
                'telegram_id': str(entity.id),
                'username': f"@{entity.username}" if entity.username else None,
                'title': entity.title,
                'description': full_channel.full_chat.about or '',
                'subscriber_count': full_channel.full_chat.participants_count or 0,
                'verified': entity.verified,
                'scam': entity.scam,
                'restricted': entity.restricted,
                'created_at': entity.date.isoformat() if hasattr(entity, 'date') else None
            }
            
            # Get recent posts (last 30)
            posts = []
            date_limit = datetime.now(timezone.utc) - timedelta(days=60)
            
            async for message in self.client.iter_messages(entity, limit=30):
                if message.date < date_limit:
                    break
                
                posts.append({
                    'telegram_message_id': message.id,
                    'text': message.text or '',
                    'views': message.views or 0,
                    'forwards': message.forwards or 0,
                    'replies': message.replies.replies if message.replies else 0,
                    'posted_at': message.date.isoformat(),
                    'has_media': message.media is not None
                })
            
            return {
                "success": True,
                "channel": channel_data,
                "posts": posts
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def disconnect(self):
        await self.client.disconnect()

async def main():
    if len(sys.argv) < 2:
        print(json.dumps({"success": False, "error": "Username required"}))
        return

    username = sys.argv[1]
    fetcher = SingleChannelFetcher()
    
    try:
        await fetcher.connect()
        result = await fetcher.fetch(username)
        print(json.dumps(result, ensure_ascii=False))
    except Exception as e:
        print(json.dumps({"success": False, "error": str(e)}))
    finally:
        await fetcher.disconnect()

if __name__ == '__main__':
    asyncio.run(main())
