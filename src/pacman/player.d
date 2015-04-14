module pacman.player;

import std.experimental.logger;
import std.math;
import std.string;

import gfm.sdl2;
import gfm.math: degrees;

import pacman;
import pacman.texture;
import pacman.globals;

final class Player
{
    enum NUM_TEXTURES = 16;
    enum ANIMATION_DELAY = 0.015;
    enum PIXELS_PER_SECOND = TILE_SIZE * 3.5;
    
    vec2i gridPosition = vec2i(0, 0); //position within the grid
    vec2 screenPosition = vec2(0, 0);
    vec2i wantedVelocity = vec2i(0, 0);
    vec2 velocity = vec2(0, 0);
    
    SDL2Texture[] animationFrames;
    SDL2Texture activeTexture;
    
    uint textureIndex;
    bool animate = true;
    bool incrementTexture = true;
    real lastAnimationTime = 0;
    
    real rotation = 0;
    
    bool startMoving = false;
    bool moving = false;
    
    this()
    {
        foreach(index; 0 .. NUM_TEXTURES)
            animationFrames ~= load_texture("res/player%d.png".format(index));
        
        activeTexture = animationFrames[0];
    }
    
    ~this()
    {
        foreach(texture; animationFrames)
            texture.close;
    }
    
    void update()
    {
        update_velocity;
        update_position;
        
        //screenPosition += timeDelta * velocity * PIXELS_PER_SECOND;
        
        if(animate && timeSeconds - lastAnimationTime > ANIMATION_DELAY)
        {
            if(incrementTexture)
                textureIndex++;
            else
                textureIndex--;
            
            if(textureIndex == 0 || textureIndex == animationFrames.length - 1)
                incrementTexture = !incrementTexture;
            
            activeTexture = animationFrames[textureIndex];
            lastAnimationTime = timeSeconds;
        }
    }
    
    void update_velocity()
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
            wantedVelocity.y -= 1;
            any = true;
        }
        
        if(sdl.keyboard.isPressed(SDLK_DOWN))
        {
            wantedVelocity.y += 1;
            any = true;
        }
        
        startMoving = any;
    }
    
    void update_position()
    {
        if(!moving && !startMoving)
            return;
        
        if(!moving && startMoving)
        {
            rotation = 180 + atan2(cast(real)wantedVelocity.y, cast(real)wantedVelocity.x).degrees;
            velocity = wantedVelocity;
            gridPosition += cast(vec2i)velocity;
            startMoving = false;
            moving = true;
        }
        
        immutable newScreenPosition = (gridPosition + velocity) * TILE_SIZE;
        immutable diff = screenPosition - newScreenPosition;
        immutable absDiff = vec2(diff.x.abs, diff.y.abs);
        immutable epsilon = TILE_SIZE;
        
        if(absDiff.x <= epsilon && absDiff.y <= epsilon)
        {
            moving = false;
            screenPosition = gridPosition * TILE_SIZE;
            
            return;
        }
        
        screenPosition += velocity * PIXELS_PER_SECOND * timeDelta;
    }
    
    void render()
    {
        const width = activeTexture.width;
        const height = activeTexture.height;
        auto src = SDL_Rect(0, 0, width, height);
        auto dst = SDL_Rect(cast(int)screenPosition.x, cast(int)screenPosition.y, width, height);
        auto rotOrigin = SDL_Point(cast(int)(width * 0.5L), cast(int)(height * 0.5L));
        
        renderer.copyEx(
            activeTexture,
            src,
            dst,
            rotation,
            &rotOrigin,
            SDL_FLIP_NONE
        );
    }
}