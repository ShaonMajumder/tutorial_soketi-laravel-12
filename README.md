### Soketi Introduction
soketi selfhosted opensource websocket-server

### Clone docker-template
```bash
git clone https://github.com/ShaonMajumder/docker-template-laravel-12-php-8.3-npm-mysql-redis-nginx-queue-soketi.git tutorial_soketi-laravel-12
cd tutorial_soketi-laravel-12
```

### Build the container

```bash
docker-compose --env-file environment/.env up --build
```
- for observilibity we can check at console
- Wait and check successfully starting all service

### Check soketi-server service is running

In browser visit http://localhost:6001/
output: ok 
- if ok then soketi-server is running ok

### Go inside Container
in another tab of terminal:
```bash
docker exec -it laravel-app bash
```
- looks like this **root@f554ac220dac:/var/www/html#** when you enter inside container

inside container run:
```bash
curl http://soketi-server:6001
```
output : ok 
- if ok then soketi-server is running ok

### Preparing Npm
preparing container nodejs dependencies : 
```bash
npm install # to install node modules
npm run build # to preapre vite engine
```

### Install Broadcasting
continue in the container
```bash
php artisan install:broadcasting
```
follow the rest of the flow:
```bash
 Which broadcasting driver would you like to use? ────────────┐
 │   ○ Laravel Reverb                                           │
 │ › ● Pusher                                                   │
 │   ○ Ably  

# Select Pusher and Press Enter

 Which broadcasting driver would you like to use? ────────────┐
 │ Pusher                                                       │
 └──────────────────────────────────────────────────────────────┘

 ┌ Pusher App ID ───────────────────────────────────────────────┐
 │ 1234                                                         │
 └──────────────────────────────────────────────────────────────┘

 ┌ Pusher App Key ──────────────────────────────────────────────┐
 │ •••••••••                                                    │
 └──────────────────────────────────────────────────────────────┘

 ┌ Pusher App Secret ───────────────────────────────────────────┐
 │ ••••••••••                                                   │
 └──────────────────────────────────────────────────────────────┘

 ┌ Pusher App Cluster ──────────────────────────────────────────┐
 │ › ● mt1                                                    ┃ │
 │   ○ us2                                                    │ │
 │   ○ us3                                                    │ │
 │   ○ eu                                                     │ │
 │   ○ ap1    

# Select mt1 and Enter 

# pusher-php-server will be installed by default

 Would you like to install and build the Node dependencies required for br… ┐
 │ ● Yes / ○ No   

    
   INFO  Installing and building Node dependencies.


up to date, audited 98 packages in 1s

22 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities

> build
> vite build

vite v6.3.5 building for production...
✓ 59 modules transformed.
public/build/manifest.json              0.27 kB │ gzip:  0.15 kB
public/build/assets/app-BLzl-bg6.css   33.54 kB │ gzip:  8.51 kB
public/build/assets/app-CqvyoFfN.js   114.41 kB │ gzip: 36.11 kB
✓ built in 2.09s
```

INFO : laravel-echo and pusher-js npm library will be installed, no need to manually install.
If failed installing node dependencies, then you can manually run:
```bash
npm install laravel-echo pusher-js
npm run build
```
- check if failed or success fully installed 
- hope so .env is not changed. If changed , check everything is ok, as previous. If changed then **php artisan config:clear** to load changes of .env 

### Check broadcasting config
check config/broadcasting.php: 
```php
'pusher' => [
            'driver' => 'pusher',
            'key' => env('PUSHER_APP_KEY'),
            'secret' => env('PUSHER_APP_SECRET'),
            'app_id' => env('PUSHER_APP_ID'),
            'options' => [
                'cluster' => env('PUSHER_APP_CLUSTER'),
                'host' => env('PUSHER_HOST') ?: 'api-'.env('PUSHER_APP_CLUSTER', 'mt1').'.pusher.com',
                'port' => env('PUSHER_PORT', 443),
                'scheme' => env('PUSHER_SCHEME', 'https'),
                'encrypted' => false, // true, revert and check
                'useTLS' => env('PUSHER_SCHEME', 'https') === 'https',
            ],
            'client_options' => [
                // Guzzle client options: https://docs.guzzlephp.org/en/stable/request-options.html
            ],
        ],
```

### Creating Event

```bash
php artisan make:event NewMessage
```

Edit NewMessage :
```bash
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

class NewMessage implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $sender_id;
    public $message;

    /**
     * Create a new event instance.
     */
    public function __construct($sender_id, $message)
    {
        $this->sender_id = $sender_id;
        $this->message = $message;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new Channel('message-box'),
        ];
    }

    public function broadcastWith()
    {
        return [
            'sender_id' => $this->sender_id,
            'message' => $this->message,
        ];
    }
}
```

### Soketi Backend Check
now inside container:
```bash
php artisan tinker
```
shell will appear like this:
```bash
Psy Shell v0.12.8 (PHP 8.3.21 — cli) by Justin Hileman
>
```
Now trigger the event:
```bash
event(new \App\Events\NewMessage(1, 'Hello from server!'));
```
output: []

In another terminal, immediately check log, after previously triggering the event:
```bash
docker-compose logs soketi
```

In log you can find something like this:
```bash
.....
 [Sun May 25 2025 19:13:33 GMT+0000 (Coordinated Universal Time)] ⚡ HTTP Payload received   

{
  name: 'App\\Events\\NewMessage',
  data: '{"sender_id":1,"message":"Hello from server!"}',
  channel: 'message-box'
}
.....
```

### Set Frontend
edit resources/js/echo.js:

```js
import Echo from 'laravel-echo';

import Pusher from 'pusher-js';
window.Pusher = Pusher;

window.Echo = new Echo({
    broadcaster: "pusher",
    key: import.meta.env.VITE_PUSHER_APP_KEY,
    cluster: import.meta.env.VITE_PUSHER_APP_CLUSTER,
    forceTLS: false, //true,
    wsHost: 'localhost', //import.meta.env.VITE_PUSHER_HOST,
    wsPort: import.meta.env.VITE_PUSHER_PORT,
    wssPort: import.meta.env.VITE_PUSHER_PORT,
    enabledTransports: ["ws", "wss"],
});
```

Build for production:
```bash
npm run build
```

in welcome.blade.php, at end of before </body>:
```php
        <script>
            document.addEventListener('DOMContentLoaded', function () {
                if (window.Echo) {
                    window.Echo.channel('message-box').listen('NewMessage', (e) => {
                        console.log('Message received', e);
                    });
                } else {
                    console.error('Echo is not defined');
                }
            });
        </script>
    </body>
```

### Check Demo
In browser visit to http://localhost:8000/
and open console

parallaly, now in terminal inside container:
```bash
php artisan tinker
```
shell will appear like this:
```bash
Psy Shell v0.12.8 (PHP 8.3.21 — cli) by Justin Hileman
>
```
Now trigger the event:
```bash
event(new \App\Events\NewMessage(1, 'Hello from server!'));
```
output: []

See at console:
![png](screenshots/listening.png)

### Build Unit Test
continue inside container
```bash
php artisan make:test Broadcast/NewMessageTest
```

edit tests\Feature\Broadcast\NewMessageTest.php :
```php
<?php

namespace Tests\Feature\Broadcast;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Events\NewMessage;
use Illuminate\Support\Facades\Event;

class NewMessageTest extends TestCase
{
    /**
     * A basic feature test example.
     */
    // public function test_example(): void
    // {
    //     $response = $this->get('/');

    //     $response->assertStatus(200);
    // }

    public function test_event_is_broadcasted_on_correct_channel()
    {
        Event::fake([NewMessage::class]);

        event(new NewMessage(1, 'Unit test message'));

        Event::assertDispatched(NewMessage::class, function ($event) {
            return $event->sender_id === 1 &&
                $event->message === 'Unit test message' &&
                in_array('message-box', array_map(fn ($c) => $c->name, $event->broadcastOn()));
        });
    }
}
```

### Add CI
### Create GitHub Actions Workflow
Create the file:
```bash
git init
code .github/workflows/ci.yml
```

edit .github/workflows/ci.yml :
```yml

```