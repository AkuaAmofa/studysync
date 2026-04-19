# StudySync API

Express/Node.js REST API backend for the StudySync mobile app.

## Prerequisites

- Node.js >= 18
- A running MySQL server accessible with the credentials below

## Setup

```bash
cd backend
npm install
```

Copy `.env.example` to `.env` and fill in your values (or use the provided `.env`):

```bash
cp .env.example .env
```

## Environment Variables

| Variable     | Description                        |
|--------------|------------------------------------|
| PORT         | Port the server listens on         |
| DB_HOST      | MySQL host                         |
| DB_PORT      | MySQL port (default 3306)          |
| DB_USER      | MySQL username                     |
| DB_PASSWORD  | MySQL password                     |
| DB_NAME      | MySQL database name                |
| JWT_SECRET   | Secret key for signing JWT tokens  |

## Running

```bash
# Production
npm start

# Development (auto-reload with nodemon)
npm run dev
```

## Health Check

```
GET /health
```

Returns `{ status: 'ok', app: 'StudySync API', timestamp: '...' }`.

## API Endpoints

### Auth

| Method | Path                  | Auth? | Description        |
|--------|-----------------------|-------|--------------------|
| POST   | /api/auth/register    | No    | Register new user  |
| POST   | /api/auth/login       | No    | Login, get token   |

**Register body:**
```json
{ "name": "", "email": "", "password": "", "programme": "", "year_group": "" }
```

**Login body:**
```json
{ "email": "", "password": "" }
```

Both return `{ token, user }`.

### Groups (all require `Authorization: Bearer <token>`)

| Method | Path                      | Description                      |
|--------|---------------------------|----------------------------------|
| POST   | /api/groups               | Create a study group             |
| GET    | /api/groups/nearby?lat=&lng= | Get groups within 5 km        |
| GET    | /api/groups/:id           | Get group by ID                  |
| PATCH  | /api/groups/:id/end       | End a group (creator only)       |
| POST   | /api/groups/:id/join      | Join a group                     |
| DELETE | /api/groups/:id/leave     | Leave a group                    |
| GET    | /api/groups/:id/members   | List group members               |

**Create group body:**
```json
{
  "course_name": "",
  "description": "",
  "latitude": 0.0,
  "longitude": 0.0,
  "location_name": "",
  "max_size": 10
}
```

## Database Tables Expected

- `ss_users` — user_id (PK), name, email, password_hash, programme, year_group, role
- `ss_study_groups` — group_id (PK), course_name, description, latitude, longitude, location_name, max_size, creator_id (FK), expires_at, status
- `ss_group_members` — group_id (FK), user_id (FK), joined_at
