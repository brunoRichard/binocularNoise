%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Originally designed by J.K. DeFord -- function variables: 
%in_image = the image passed to the function (which cannot be of the type uint8)
%mea = the background value applied to the area outside the max radius
%B = the PERCENTAGE of the image that is effectively "blurred"
%A linear ramp is applied to the viewable image in the direction of the background value
%%Author: Bruce C. Hansen, Ph.D.
%         Post-Doctoral Research Fellow
%         McGill Vision Research Unit
%         Department of Ophthalmology
%         McGill University
%         687 Pine Avenue West, Rm. H4-14
%         Montreal, Quebec, Canada  H3A 1A1
%         Lab: (514) 934-1934   Ext. 34816
%         Fax: (514) 843-1691
%         Email: bruce.hansen@mcgill.ca
%         Web: www.psych.mcgill.ca/labs/mvr/home.html
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function change_matrix = CIRC_EDGE_RAMP(in_image, mea, B)

change_matrix = in_image;

[H W D] = size(in_image);
image_size = H;

bs = H * B;

max_r = image_size/2;

x2 = (-1*(image_size/2));
y2 = (-1*(image_size/2));

for x = 1:H
   for y = 1:W
      radius(x,y) = round(sqrt((x2^2)+(y2^2)));
      if(radius(x,y)>=(max_r-bs))
         n = max_r - radius(x,y);
         change_matrix(x,y)=(((bs-n)/bs)* mea)+((n/bs)*in_image(x,y));
      end;
      if(radius(x,y) > max_r)
         change_matrix(x,y) = mea;
      end;
      y2 = y2 + 1;
   end;
   x2 = x2 + 1;
   y2 = (-1*(image_size/2));
end;


