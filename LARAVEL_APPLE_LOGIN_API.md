# Laravel Backend: Apple Sign-In API

The Flutter app sends Apple credentials to your Laravel backend. You need to add an endpoint to verify the token and authenticate the user.

## Endpoint

**POST** `/api/applelogin`

## Request Body (JSON)

```json
{
  "identity_token": "eyJraWQiOi...",  // Required: JWT from Apple
  "authorization_code": "c123...",     // Optional
  "email": "user@privaterelay.appleid.com",  // Optional (only on first sign-in)
  "name": "John Doe"                   // Optional (only on first sign-in)
}
```

## Response (Success: 200/201)

Same format as `/api/login` and `/api/register`:

```json
{
  "access_token": "your-laravel-sanctum-token",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com",
    "phone": null,
    ...
  }
}
```

## Backend Implementation Steps

1. **Verify the identity token** with Apple's public keys (https://appleid.apple.com/auth/keys)
2. **Decode the JWT** to get `sub` (Apple user ID) and optionally `email`
3. **Find or create user** in your database:
   - If user exists (by `apple_id` or email): return their token
   - If new user: create with `email`, `name` from request, store `apple_id` (sub)
4. **Return** Laravel Sanctum token + user object

## Example Laravel Controller (pseudo-code)

```php
public function appleLogin(Request $request) {
    $identityToken = $request->input('identity_token');
    $email = $request->input('email');
    $name = $request->input('name');
    
    // 1. Verify JWT with Apple's public keys (use firebase/php-jwt or similar)
    // 2. Extract 'sub' (Apple user ID) from token
    // 3. Find user by apple_id or create new one
    // 4. Create Sanctum token: $user->createToken('apple')->plainTextToken;
    // 5. Return ['access_token' => $token, 'token_type' => 'Bearer', 'user' => $user];
}
```

## Route

Add to `routes/api.php`:

```php
Route::post('/applelogin', [AuthController::class, 'appleLogin']);
```

Ensure this route is in the `auth:sanctum`-excluded group (no auth required for login).
