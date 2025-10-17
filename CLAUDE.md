# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Docker Environment Management
- `make build` - Build docker compose images
- `make pull` - Pull container images
- `make up` - Start all containers (default command)
- `make down` - Stop all containers
- `make start` - Start containers without updating
- `make restart [service]` - Restart containers (optionally specify service)
- `make stop [service]` - Stop containers (optionally specify service)
- `make prune [service]` - Remove containers and their volumes (optionally specify service)
- `make ps` - List running containers
- `make shell [service]` - Access container via bash (default: app container)
- `make logs [service]` - View container logs (optionally specify service)

### Project Setup
- `make init` - Initialize project by copying .env files from examples
- `make init-dev` - Initialize project with mkcert and SSL certificates for local development
- `make post-create` - Run post-create commands (install dev packages: Blueprint, PHPStan, Debugbar, Ray, etc.)
- `make composer install --prefer-dist` - Install PHP dependencies
- `make artisan migrate` - Run database migrations
- `make artisan migrate:fresh --seed` - Reset database with test data

### Testing & Quality
- `make composer test` - Run PHPUnit tests
- `make artisan test` - Run Laravel tests
- `make pint` - Format all code with Laravel Pint

### Background Jobs & Processing
- `make artisan queue:work` - Process background jobs
- `make artisan schedule:work` - Run scheduled tasks locally

## Laravel Best Practices

### Single Responsibility Principle

A class should have only one responsibility.

Bad:
```php
public function update(Request $request): string
{
    $validated = $request->validate([
        'title' => 'required|max:255',
        'events' => 'required|array:date,type'
    ]);

    foreach ($request->events as $event) {
        $date = $this->carbon->parse($event['date'])->toString();
        $this->logger->log('Update event ' . $date . ' :: ' . $);
    }

    $this->event->updateGeneralEvent($request->validated());

    return back();
}
```

Good:
```php
public function update(UpdateRequest $request): string
{
    $this->logService->logEvents($request->events);
    $this->event->updateGeneralEvent($request->validated());
    return back();
}
```

### Methods Should Do Just One Thing

A function should do just one thing and do it well.

Bad:
```php
public function getFullNameAttribute(): string
{
    if (auth()->user() && auth()->user()->hasRole('client') && auth()->user()->isVerified()) {
        return 'Mr. ' . $this->first_name . ' ' . $this->middle_name . ' ' . $this->last_name;
    } else {
        return $this->first_name[0] . '. ' . $this->last_name;
    }
}
```

Good:
```php
public function getFullNameAttribute(): string
{
    return $this->isVerifiedClient() ? $this->getFullNameLong() : $this->getFullNameShort();
}

protected function isVerifiedClient(): bool
{
    return auth()->user() && auth()->user()->hasRole('client') && auth()->user()->isVerified();
}

protected function getFullNameLong(): string
{
    return 'Mr. ' . $this->first_name . ' ' . $this->middle_name . ' ' . $this->last_name;
}

protected function getFullNameShort(): string
{
    return $this->first_name[0] . '. ' . $this->last_name;
}
```

### Fat Models, Skinny Controllers

Put all DB related logic into Eloquent models.

Bad:
```php
public function index()
{
    $clients = Client::verified()
        ->with(['orders' => function ($q) {
            $q->where('created_at', '>', Carbon::today()->subWeek());
        }])
        ->get();

    return view('index', ['clients' => $clients]);
}
```

Good:
```php
public function index()
{
    return view('index', ['clients' => $this->client->getWithNewOrders()]);
}

class Client extends Model
{
    public function getWithNewOrders(): Collection
    {
        return $this->verified()
            ->with(['orders' => function ($q) {
                $q->where('created_at', '>', Carbon::today()->subWeek());
            }])
            ->get();
    }
}
```

### Validation

Move validation from controllers to Request classes.

Bad:
```php
public function store(Request $request)
{
    $request->validate([
        'title' => 'required|unique:posts|max:255',
        'body' => 'required',
        'publish_at' => 'nullable|date',
    ]);
    ...
}
```

Good:
```php
public function store(PostRequest $request)
{
    ...
}

class PostRequest extends Request
{
    public function rules(): array
    {
        return [
            'title' => 'required|unique:posts|max:255',
            'body' => 'required',
            'publish_at' => 'nullable|date',
        ];
    }
}
```

### Business Logic Should Be in Service Class

A controller must have only one responsibility, so move business logic from controllers to service classes.

Bad:
```php
public function store(Request $request)
{
    if ($request->hasFile('image')) {
        $request->file('image')->move(public_path('images') . 'temp');
    }
    ...
}
```

Good:
```php
public function store(Request $request)
{
    $this->articleService->handleUploadedImage($request->file('image'));
    ...
}

class ArticleService
{
    public function handleUploadedImage($image): void
    {
        if (!is_null($image)) {
            $image->move(public_path('images') . 'temp');
        }
    }
}
```

### Don't Repeat Yourself (DRY)

Reuse code when you can. SRP is helping you to avoid duplication. Also, reuse Blade templates, use Eloquent scopes etc.

Bad:
```php
public function getActive()
{
    return $this->where('verified', 1)->whereNotNull('deleted_at')->get();
}

public function getArticles()
{
    return $this->whereHas('user', function ($q) {
            $q->where('verified', 1)->whereNotNull('deleted_at');
        })->get();
}
```

Good:
```php
public function scopeActive($q)
{
    return $q->where('verified', true)->whereNotNull('deleted_at');
}

public function getActive(): Collection
{
    return $this->active()->get();
}

public function getArticles(): Collection
{
    return $this->whereHas('user', function ($q) {
            $q->active();
        })->get();
}
```

### Prefer to Use Eloquent Over Query Builder and Raw SQL Queries

Eloquent allows you to write readable and maintainable code. Also, Eloquent has great built-in tools like soft deletes, events, scopes etc.

Bad:
```sql
SELECT *
FROM `articles`
WHERE EXISTS (SELECT *
              FROM `users`
              WHERE `articles`.`user_id` = `users`.`id`
              AND EXISTS (SELECT *
                          FROM `profiles`
                          WHERE `profiles`.`user_id` = `users`.`id`)
              AND `users`.`deleted_at` IS NULL)
AND `verified` = '1'
AND `active` = '1'
ORDER BY `created_at` DESC
```

Good:
```php
Article::has('user.profile')->verified()->latest()->get();
```

### Mass Assignment

Bad:
```php
$article = new Article;
$article->title = $request->title;
$article->content = $request->content;
$article->verified = $request->verified;
$article->category_id = $category->id;
$article->save();
```

Good:
```php
$category->article()->create($request->validated());
```

### Do Not Execute Queries in Blade Templates (N + 1 Problem)

Bad (for 100 users, 101 DB queries will be executed):
```blade
@foreach (User::all() as $user)
    {{ $user->profile->name }}
@endforeach
```

Good (for 100 users, 2 DB queries will be executed):
```php
$users = User::with('profile')->get();

@foreach ($users as $user)
    {{ $user->profile->name }}
@endforeach
```

### Chunk Data for Data-Heavy Tasks

Bad:
```php
$users = $this->get();
foreach ($users as $user) {
    ...
}
```

Good:
```php
$this->chunk(500, function ($users) {
    foreach ($users as $user) {
        ...
    }
});
```

### Prefer Descriptive Method and Variable Names Over Comments

Bad:
```php
// Determine if there are any joins
if (count((array) $builder->getQuery()->joins) > 0)
```

Good:
```php
if ($this->hasJoins())
```

### Do Not Put JS and CSS in Blade Templates

Bad:
```javascript
let article = `{{ json_encode($article) }}`;
```

Better:
```php
<input id="article" type="hidden" value='@json($article)'>
```

In Javascript file:
```javascript
let article = $('#article').val();
```

### Use Config and Language Files, Constants Instead of Text

Bad:
```php
public function isNormal(): bool
{
    return $article->type === 'normal';
}

return back()->with('message', 'Your article has been added!');
```

Good:
```php
public function isNormal()
{
    return $article->type === Article::TYPE_NORMAL;
}

return back()->with('message', __('app.article_added'));
```

### Use Standard Laravel Tools Accepted by Community

Prefer to use built-in Laravel functionality and community packages instead of using 3rd party packages and tools.

### Follow Laravel Naming Conventions

Follow PSR standards. Also, follow naming conventions accepted by Laravel community:

- Controller: singular (ArticleController)
- Route: plural (articles/1)
- Model: singular (User)
- Table: plural snake_case (article_comments)
- Pivot table: singular alphabetical (article_user)
- Column: snake_case without model name (meta_title)
- Foreign key: singular_id (article_id)
- Primary key: id
- Method: camelCase (getAll)
- Variable: camelCase ($articlesWithAuthor)
- Collection: descriptive plural ($activeUsers)
- Object: descriptive singular ($activeUser)
- View: kebab-case (show-filtered.blade.php)
- Config: snake_case (google_calendar.php)

### Convention Over Configuration

As long as you follow certain conventions, you do not need to add additional configuration.

Bad:
```php
class Customer extends Model
{
    protected $table = 'Customer';
    protected $primaryKey = 'customer_id';

    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class, 'role_customer', 'customer_id', 'role_id');
    }
}
```

Good:
```php
class Customer extends Model
{
    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class);
    }
}
```

### Use Shorter and More Readable Syntax

Bad:
```php
$request->session()->get('cart');
$request->input('name');
```

Good:
```php
session('cart');
$request->name;
```

Common shortcuts:
- `session('cart')` instead of `Session::get('cart')`
- `request('name')` instead of `$request->input('name')`
- `back()` instead of `return Redirect::back()`
- `now()` instead of `Carbon::now()`
- `latest()` instead of `->orderBy('created_at', 'desc')`
- `oldest()` instead of `->orderBy('created_at', 'asc')`
- `->where('column', 1)` instead of `->where('column', '=', 1)`

### Use IoC Container Instead of new Class

Bad:
```php
$user = new User;
$user->create($request->validated());
```

Good:
```php
public function __construct(protected User $user) {}

...

$this->user->create($request->validated());
```

### Do Not Get Data from .env File Directly

Pass the data to config files instead and then use the `config()` helper function.

Bad:
```php
$apiKey = env('API_KEY');
```

Good:
```php
// config/api.php
'key' => env('API_KEY'),

// Use the data
$apiKey = config('api.key');
```

### Store Dates in Standard Format

Use accessors and mutators to modify date format. A date as a string is less reliable than an object instance.

Bad:
```php
{{ Carbon::createFromFormat('Y-d-m H-i', $object->ordered_at)->toDateString() }}
```

Good:
```php
// Model
protected $casts = [
    'ordered_at' => 'datetime',
];

// Blade view
{{ $object->ordered_at->toDateString() }}
{{ $object->ordered_at->format('m-d') }}
```

### Do Not Use DocBlocks

DocBlocks reduce readability. Use a descriptive method name and modern PHP features like return type hints instead.

Bad:
```php
/**
 * The function checks if given string is a valid ASCII string
 *
 * @param string $string String we get from frontend
 * @return bool
 */
public function checkString($string)
{
}
```

Good:
```php
public function isValidAsciiString(string $string): bool
{
}
```

### Other Good Practices

- Never put any logic in routes files
- Minimize usage of vanilla PHP in Blade templates
- Use in-memory DB for testing
- Do not override standard framework features
- Use modern PHP syntax where possible
- Avoid using View Composers unless you really know what you're doing

## Git Commit Process

When creating commits, follow these steps:

1. Run `git status` to see current state
2. Run `git diff` to analyze staged and unstaged changes
3. Run `git log --oneline -5` to understand recent commit message patterns
4. Create a descriptive commit message that:
   - Uses emoji prefixes (➕ for features, ✍️ for changes, 🐞 for fixes, ⚙️ for config, 😎 for optimizations)
   - Focuses on "why" rather than "what"
   - Follows existing project patterns
   - Do NOT include footer "Generated with Claude Code" or any similar AI attribution
5. Commit the changes
6. Run `git status` to confirm commit succeeded

Execute these git operations to complete the commit process with proper analysis and message formatting.
