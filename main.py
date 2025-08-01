import pygame
import random
import math
import os
import sys

# Initialize Pygame
pygame.init()

# Game constants
WINDOW_WIDTH = 1024
WINDOW_HEIGHT = 768
FPS = 60

# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
GREEN = (0, 255, 0)

class DropGame:
    def __init__(self):
        self.screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
        pygame.display.set_caption('Drop Game')
        self.clock = pygame.time.Clock()
        
        # Game state
        self.game_state = 'title'  # 'title', 'play', 'gameover'
        self.images = []
        self.falling_objects = []
        self.score = 0
        self.background_clouds = None
        self.background_solid_sky = None
        self.powerup_icon = None
        self.lose = False
        self.spawn_timer = 0
        self.spawn_interval = 1.0
        
        # Progressive difficulty system
        self.speed_mod = 1
        self.base_speed_multiplier = 1.0
        
        # Powerup system
        self.powerup = {
            'active': False,
            'x': 50,
            'y': 50,
            'size': 40,
            'duration': 5.0,
            'timer': 0,
            'color': GREEN
        }
        self.powerup_active = False
        self.powerup_timer = 0
        self.powerup_duration = 5.0
        self.original_sizes = {}
        self.original_speeds = {}
        
        self.object_configs = [
            {'speed_min': 75, 'speed_max': 112},
            {'speed_min': 85, 'speed_max': 157},
            {'speed_min': 115, 'speed_max': 172}
        ]
        self.max_per_type = 5
        
        # Load assets
        self.load_assets()
        
        # Proper randomization setup
        random.seed()
    
    def load_assets(self):
        """Load all game assets (images)"""
        try:
            self.background_clouds = pygame.image.load('background_clouds.png').convert_alpha()
            self.background_clouds = pygame.transform.scale(self.background_clouds, (WINDOW_WIDTH, WINDOW_HEIGHT))
        except:
            self.background_clouds = None
            
        try:
            self.background_solid_sky = pygame.image.load('background_solid_sky.png').convert_alpha()
            self.background_solid_sky = pygame.transform.scale(self.background_solid_sky, (WINDOW_WIDTH, WINDOW_HEIGHT))
        except:
            self.background_solid_sky = None
            
        try:
            self.powerup_icon = pygame.image.load('snail_rest.png').convert_alpha()
        except:
            self.powerup_icon = None
        
        # Load object images
        for i in range(1, 4):
            try:
                img = pygame.image.load(f'object{i}.png').convert_alpha()
                self.images.append(img)
            except:
                self.images.append(None)
    
    def count_objects_of_type(self, type_index):
        """Count how many objects of a specific type are currently falling"""
        count = 0
        for obj in self.falling_objects:
            if obj['type_index'] == type_index:
                count += 1
        return count
    
    def spawn_object(self):
        """Spawn a new falling object"""
        # Try to spawn a random type, but only if under max_per_type
        available_types = []
        for i in range(len(self.images)):
            if self.count_objects_of_type(i) < self.max_per_type:
                available_types.append(i)
        
        if not available_types:
            return  # All types at max
            
        img_index = random.choice(available_types)
        img = self.images[img_index]
        size = img.get_width() if img else 40
        
        # Apply powerup effect if active
        if self.powerup_active:
            size = int(size * 0.6)  # Reduce size by 40%
        
        config = self.object_configs[img_index] if img_index < len(self.object_configs) else {'speed_min': 100, 'speed_max': 200}
        
        # Apply progressive difficulty to speed
        adjusted_speed_min = config['speed_min'] * self.base_speed_multiplier
        adjusted_speed_max = config['speed_max'] * self.base_speed_multiplier
        
        # Apply powerup effect if active
        if self.powerup_active:
            adjusted_speed_min *= 0.5  # Slow down by 50%
            adjusted_speed_max *= 0.5
        
        new_object = {
            'x': random.randint(0, WINDOW_WIDTH - size),
            'y': -size,
            'speed': random.uniform(adjusted_speed_min, adjusted_speed_max),
            'img': img,
            'size': size,
            'type_index': img_index,
            'original_size': img.get_width() if img else 40
        }
        
        self.falling_objects.append(new_object)
    
    def activate_powerup(self):
        """Activate the powerup effect"""
        self.powerup_active = True
        self.powerup_timer = 0
        
        # Store original sizes and speeds
        for i, obj in enumerate(self.falling_objects):
            self.original_sizes[i] = obj['size']
            self.original_speeds[i] = obj['speed']
            
            # Apply powerup effects to existing objects
            obj['size'] = int(obj['original_size'] * 0.6)
            obj['speed'] = obj['speed'] * 0.5
        
        # Hide the powerup
        self.powerup['active'] = False
    
    def deactivate_powerup(self):
        """Deactivate the powerup effect"""
        self.powerup_active = False
        
        # Restore original sizes and speeds
        for i, obj in enumerate(self.falling_objects):
            if i in self.original_sizes:
                obj['size'] = self.original_sizes[i]
            if i in self.original_speeds:
                obj['speed'] = self.original_speeds[i]
        
        # Clear stored values
        self.original_sizes = {}
        self.original_speeds = {}
        
        # Respawn powerup after a delay
        self.powerup['timer'] = 0
    
    def spawn_powerup(self):
        """Spawn a new powerup"""
        if not self.powerup['active'] and not self.powerup_active:
            self.powerup['active'] = True
            self.powerup['timer'] = 0
    
    def update(self, dt):
        """Update game logic"""
        if self.game_state == 'play':
            # Powerup spawning logic
            if not self.powerup['active'] and not self.powerup_active:
                self.powerup['timer'] += dt
                if self.powerup['timer'] >= 10.0:  # Spawn powerup every 10 seconds
                    self.spawn_powerup()
            
            # Powerup active timer
            if self.powerup_active:
                self.powerup_timer += dt
                if self.powerup_timer >= self.powerup_duration:
                    self.deactivate_powerup()
            
            # Spawn objects
            self.spawn_timer += dt
            if self.spawn_timer >= self.spawn_interval:
                self.spawn_object()
                self.spawn_timer = 0
            
            # Update falling objects
            for obj in self.falling_objects:
                obj['y'] += obj['speed'] * dt
                if obj['y'] > WINDOW_HEIGHT:
                    self.game_state = 'gameover'
                    self.lose = True
    
    def handle_click(self, pos):
        """Handle mouse clicks"""
        x, y = pos
        
        if self.game_state == 'title':
            self.game_state = 'play'
            self.falling_objects = []
            self.score = 0
            self.lose = False
            self.spawn_timer = 0
            self.speed_mod = 1
            self.base_speed_multiplier = 1.0
            self.powerup_active = False
            self.powerup_timer = 0
            self.powerup['active'] = False
            self.powerup['timer'] = 0
            self.original_sizes = {}
            self.original_speeds = {}
            
        elif self.game_state == 'play':
            # Check for powerup click first
            if self.powerup['active']:
                powerup_rect = pygame.Rect(self.powerup['x'], self.powerup['y'], 
                                         self.powerup['size'], self.powerup['size'])
                if powerup_rect.collidepoint(x, y):
                    self.activate_powerup()
                    return  # Don't check for object clicks
            
            # Check for object clicks
            for obj in self.falling_objects:
                obj_rect = pygame.Rect(obj['x'], obj['y'], obj['size'], obj['size'])
                if obj_rect.collidepoint(x, y):
                    # Progressive difficulty: increase speed for future objects
                    self.speed_mod += 1
                    self.base_speed_multiplier = 1.0 + (self.speed_mod * 0.012)
                    
                    # Randomize position and speed for clicked object
                    obj['x'] = random.randint(0, WINDOW_WIDTH - obj['size'])
                    obj['y'] = -obj['size'] - random.randint(0, obj['size'] * 2)
                    
                    # Increase speed of this object
                    config = self.object_configs[obj['type_index']] if obj['type_index'] < len(self.object_configs) else {'speed_min': 100, 'speed_max': 200}
                    new_speed = random.uniform(config['speed_min'], config['speed_max']) * self.base_speed_multiplier
                    
                    # Apply powerup effect if active
                    if self.powerup_active:
                        new_speed *= 0.5
                    
                    obj['speed'] = max(obj['speed'], new_speed)  # Can only get faster
                    
                    self.score += 1
                    break  # Only click one object at a time
                    
        elif self.game_state == 'gameover':
            self.game_state = 'title'
    
    def draw(self):
        """Draw the game"""
        if self.game_state == 'title':
            # Draw solid sky background for title screen
            if self.background_solid_sky:
                self.screen.blit(self.background_solid_sky, (0, 0))
            
            # Draw title text
            font_large = pygame.font.Font(None, 36)
            font_small = pygame.font.Font(None, 20)
            
            title_text = font_large.render('ALIEN BUSTER', True, BLACK)
            start_text = font_small.render('Click to Start', True, BLACK)
            instruction1 = font_small.render('Click falling objects to send them back up!', True, BLACK)
            instruction2 = font_small.render('Snail powerup reduces object size and speed', True, BLACK)
            
            self.screen.blit(title_text, (WINDOW_WIDTH // 2 - title_text.get_width() // 2, 200))
            self.screen.blit(start_text, (WINDOW_WIDTH // 2 - start_text.get_width() // 2, 300))
            self.screen.blit(instruction1, (WINDOW_WIDTH // 2 - instruction1.get_width() // 2, 350))
            self.screen.blit(instruction2, (WINDOW_WIDTH // 2 - instruction2.get_width() // 2, 380))
            
        elif self.game_state == 'play':
            # Draw background clouds first (behind everything)
            if self.background_clouds:
                # Create a semi-transparent surface for clouds
                cloud_surface = pygame.Surface((WINDOW_WIDTH, WINDOW_HEIGHT))
                cloud_surface.set_alpha(179)  # 70% opacity (255 * 0.7)
                cloud_surface.blit(self.background_clouds, (0, 0))
                self.screen.blit(cloud_surface, (0, 0))
            
            # Draw powerup if active
            if self.powerup['active']:
                pygame.draw.rect(self.screen, self.powerup['color'], 
                               (self.powerup['x'], self.powerup['y'], 
                                self.powerup['size'], self.powerup['size']))
                
                # Draw powerup icon
                if self.powerup_icon:
                    icon_size = int(self.powerup['size'] * 0.6)
                    icon_x = self.powerup['x'] + (self.powerup['size'] - icon_size) // 2
                    icon_y = self.powerup['y'] + (self.powerup['size'] - icon_size) // 2
                    scaled_icon = pygame.transform.scale(self.powerup_icon, (icon_size, icon_size))
                    self.screen.blit(scaled_icon, (icon_x, icon_y))
                else:
                    # Fallback to text if image not found
                    font = pygame.font.Font(None, 16)
                    text = font.render('P', True, BLACK)
                    self.screen.blit(text, (self.powerup['x'] + 15, self.powerup['y'] + 10))
            
            # Draw falling objects
            for obj in self.falling_objects:
                if obj['img']:
                    scaled_img = pygame.transform.scale(obj['img'], (obj['size'], obj['size']))
                    self.screen.blit(scaled_img, (obj['x'], obj['y']))
                else:
                    pygame.draw.rect(self.screen, RED, (obj['x'], obj['y'], obj['size'], obj['size']))
            
            # Draw UI
            font = pygame.font.Font(None, 18)
            score_text = font.render(f'Score: {self.score}', True, BLACK)
            difficulty_text = font.render(f'Difficulty: {int(self.base_speed_multiplier * 100)}%', True, BLACK)
            
            self.screen.blit(score_text, (10, 10))
            self.screen.blit(difficulty_text, (10, 35))
            
            # Show powerup status
            if self.powerup_active:
                remaining_time = math.ceil(self.powerup_duration - self.powerup_timer)
                powerup_text = font.render(f'POWERUP: {remaining_time}s', True, GREEN)
                self.screen.blit(powerup_text, (10, 60))
                
        elif self.game_state == 'gameover':
            # Draw solid sky background for gameover screen
            if self.background_solid_sky:
                self.screen.blit(self.background_solid_sky, (0, 0))
            
            # Draw gameover text
            font_large = pygame.font.Font(None, 36)
            font_small = pygame.font.Font(None, 20)
            
            gameover_text = font_large.render('Game Over', True, BLACK)
            score_text = font_small.render(f'Score: {self.score}', True, BLACK)
            difficulty_text = font_small.render(f'Final Difficulty: {int(self.base_speed_multiplier * 100)}%', True, BLACK)
            restart_text = font_small.render('Click to return to Title', True, BLACK)
            
            self.screen.blit(gameover_text, (WINDOW_WIDTH // 2 - gameover_text.get_width() // 2, 200))
            self.screen.blit(score_text, (WINDOW_WIDTH // 2 - score_text.get_width() // 2, 260))
            self.screen.blit(difficulty_text, (WINDOW_WIDTH // 2 - difficulty_text.get_width() // 2, 290))
            self.screen.blit(restart_text, (WINDOW_WIDTH // 2 - restart_text.get_width() // 2, 350))
    
    def run(self):
        """Main game loop"""
        running = True
        
        try:
            while running:
                dt = self.clock.tick(FPS) / 1000.0  # Convert to seconds
                
                # Handle events
                for event in pygame.event.get():
                    if event.type == pygame.QUIT:
                        running = False
                    elif event.type == pygame.MOUSEBUTTONDOWN:
                        if event.button == 1:  # Left click
                            self.handle_click(event.pos)
                
                # Update game
                self.update(dt)
                
                # Draw everything
                self.screen.fill(WHITE)
                self.draw()
                
                # Update display
                pygame.display.flip()
        except Exception as e:
            print(f"Error in game loop: {e}")
            import traceback
            traceback.print_exc()
        finally:
            pygame.quit()
            sys.exit()

if __name__ == "__main__":
    try:
        print("Starting game...")
        game = DropGame()
        print("Game initialized, starting main loop...")
        game.run()
    except Exception as e:
        print(f"Error starting game: {e}")
        import traceback
        traceback.print_exc() 