# Make slurmcollie hex sticker


library(hexSticker)
sticker('inst/border_collie.png', 
        package = 'slurmcollie', 
        p_y = 0.5, p_size=20, 
        p_color = 'black', 
        s_x=1, s_y=1.25, s_width=0.8, 
        h_color = 'black', h_fill = 'white', 
        white_around_sticker = FALSE, 
        filename = 'man/figures/hexsticker.png')

