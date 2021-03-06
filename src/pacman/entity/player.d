module pacman.entity.player;

import std.experimental.logger;
import std.math;
import std.string;

import gfm.sdl2;
import gfm.math: degrees;

import pacman.entity.creature;
import pacman.entity.grid;
import pacman.gl.texture;
import pacman.globals;
import pacman;

final class Player: Creature
{
    enum NUM_TEXTURES = 16;
    enum ANIMATION_DELAY = 0.015;
    enum DEATH_TIME = 100; //duration of the death animation, in ticks
    enum EMPOWERED_TIME = 500; //duration the empowered state lasts, in ticks
    enum POINTS_TASTY = 1; //points received for eating a tasty floor
    enum POINTS_VERY_TASTY = 5; //points received for eating a very tasty floor
    enum POINTS_GHOST = 10; //points received for eating a ghost
    
    TextureData[NUM_TEXTURES] animationFrames;
    TextureData activeTexture;
    
    bool incrementTexture = true;
    real lastAnimationTime = 0;
    real rotation = 0; //in degrees
    uint textureIndex;
    vec3f color = vec3i(255, 255, 255);
    bool empowered; //ate a very tasty floor
    uint empoweredTime;
    uint score;
    
    this()
    {
        foreach(index; 0 .. NUM_TEXTURES)
            animationFrames[index] = get_texture("res/player%d.png".format(index));
        
        activeTexture = animationFrames[0];
    }
    
    override void reset()
    {
        super.reset();
        
        color = vec3i(255, 255, 255);
        rotation = 0;
        activeTexture = animationFrames[0];
        empowered = false;
        empoweredTime = 0;
        score = 0;
    }
    
    override void update()
    {
        super.update;
        
        if(dead)
        {
            enum spinupMul = 50;
            enum maxSpin = spinupMul / 2;
            real deadPercent = cast(real)deadTime / DEATH_TIME;
            rotation += fmin(deadPercent * spinupMul, deadPercent * maxSpin);
            
            foreach(_; 0 .. 3)
                next_texture;
            
            return;
        }
        
        if(empowered)
        {
            empoweredTime++;
            
            if(empoweredTime >= EMPOWERED_TIME)
            {
                empowered = false;
                empoweredTime = 0;
            }
        }
        
        if(moving && timeSeconds - lastAnimationTime > ANIMATION_DELAY)
        {
            next_texture;
            
            lastAnimationTime = timeSeconds;
        }
    }
    
    override void update_velocity()
    {
        wantedVelocity = vec2i(0, 0);
        bool any;
        
        if(sdl.keyboard.isPressed(SDLK_LEFT))
        {
            wantedVelocity.x -= 1;
            any = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_RIGHT))
        {
            wantedVelocity.x += 1;
            any = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_UP))
        {
            wantedVelocity.y += 1;
            any = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_DOWN))
        {
            wantedVelocity.y -= 1;
            any = true;
        }
        
        startMoving = any;
    }
    
    override void begin_moving()
    {
        rotation = 180 + atan2(cast(real)wantedVelocity.y, cast(real)wantedVelocity.x).degrees;
    }
    
    override void done_moving()
    {
        Tile *currentTile = grid[gridPosition];
        
        if(currentTile.type == TileType.TASTY_FLOOR)
        {
            currentTile.type = TileType.FLOOR;
            score += POINTS_TASTY;
        }
        
        if(currentTile.type == TileType.VERY_TASTY_FLOOR)
        {
            currentTile.type = TileType.FLOOR;
            empowered = true;
            score += POINTS_VERY_TASTY;
        }
    }
    
    override void render()
    {
        renderer.copy(
            activeTexture,
            cast(int)screenPosition.x,
            cast(int)screenPosition.y,
            rotation,
            color,
        );
    }
    
    void next_texture()
    {
        if(incrementTexture)
            textureIndex++;
        else
            textureIndex--;
        
        if(textureIndex == 0 || textureIndex == NUM_TEXTURES - 1)
            incrementTexture = !incrementTexture;
        
        activeTexture = animationFrames[textureIndex];
    }
}
