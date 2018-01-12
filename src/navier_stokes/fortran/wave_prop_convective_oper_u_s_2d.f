cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c     Computes r = u.grad(q)
c
c     where u is vector valued face centered velocity
c     q is cell centered with depth d
c     returns r_data at cell centeres
c     computes grad(q) using weno + wave propagation
c     interpolation coefficients and weights must be provided
c     currently only works for interp orders 3 (k=2) and 5 (k=3)
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      subroutine wave_prop_convective_oper_u_s_2d(
     &            q_data, q_gcw,
     &            u_data_0, u_data_1, u_gcw,
     &            r_data, r_gcw, d,
     &            ilower0, ilower1,
     &            iupper0, iupper1,
     &            dx,
     &            interp_coefs, interp_coefs_centers,
     &            smooth_weights, smooth_weights_centers, k)

      implicit none
      Integer ilower0, iupper0
      Integer ilower1, iupper1
      Integer d

      Integer q_gcw
      real*8 q_data((ilower0-q_gcw):(iupper0+q_gcw),
     &              (ilower1-q_gcw):(iupper1+q_gcw),
     &               0:(d-1))

      real*8 s_data_0(ilower0:(iupper0+1),
     &               ilower1:iupper1,
     &                0:1)
      real*8 s_data_1(ilower1:(iupper1+1),
     &               ilower0:iupper0,
     &                0:1)

      Integer u_gcw
      real*8 u_data_0((ilower0-u_gcw):(iupper0+u_gcw+1),
     &               (ilower1-u_gcw):(iupper1+u_gcw))
      real*8 u_data_1((ilower0-u_gcw):(iupper0+u_gcw),
     &               (ilower1-u_gcw):(iupper1+u_gcw+1))

      Integer r_gcw
      real*8 r_data((ilower0-r_gcw):(iupper0+r_gcw),
     &             (ilower1-r_gcw):(iupper1+r_gcw),
     &              0:(d-1))

      real*8 dx(0:1)

      Integer k, j
      Integer i0, i1
      real*8 interp_coefs(0:k,0:(k-1))
      real*8 smooth_weights(0:(k-1))
      real*8 interp_coefs_centers(0:k,0:(k-1))
      real*8 smooth_weights_centers(0:(k-1))


      do j=0,(d-1)
      call reconstruct_data_on_patch_2d(q_data(:,:,j), q_gcw,
     &             s_data_0, s_data_1, 0,
     &             ilower0, ilower1, iupper0, iupper1,
     &             interp_coefs, interp_coefs_centers,
     &             smooth_weights, smooth_weights_centers, k)

      do i1 = ilower1, iupper1
        do i0 = ilower0, iupper0
         r_data(i0,i1,j) =
     &     1.d0/dx(0)*(max(u_data_0(i0,i1),0.d0)*
     &     (s_data_0(i0,i1,1)-s_data_0(i0,i1,0))
     &     + min(u_data_0(i0+1,i1),0.d0)*
     &     (s_data_0(i0+1,i1,1)-s_data_0(i0+1,i1,0))
     &     + 0.5d0*(u_data_0(i0+1,i1)+u_data_0(i0,i1))*
     &     (s_data_0(i0+1,i1,0)-s_data_0(i0,i1,1)))

         r_data(i0,i1,j) = r_data(i0,i1,j) +
     &     1.d0/dx(1)*(max(u_data_1(i0,i1),0.d0)*
     &     (s_data_1(i1,i0,1)-s_data_1(i1,i0,0))
     &     + min(u_data_1(i0,i1+1),0.d0)*
     &     (s_data_1(i1+1,i0,1)-s_data_1(i1+1,i0,0))
     &     + 0.5d0*(u_data_1(i0,i1+1)+u_data_1(i0,i1))*
     &     (s_data_1(i1+1,i0,0)-s_data_1(i1,i0,1)))
!         print *, r_data(i0,i1,j)
        enddo
      enddo
      enddo
      end subroutine

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c       Reconstructs data on patches using a weno scheme
c       the convex and interpolation weights must be supplied
c
c       q_data is cell centered with depth 1
c       r_data_* are face centered with depth 2
c         and return the values reconstructed from each side
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      subroutine reconstruct_data_on_patch_2d(q_data, q_gcw,
     &            r_data_0, r_data_1, r_gcw,
     &            ilower0, ilower1, iupper0, iupper1,
     &            weights_cell_sides, weights_cell_centers,
     &            smooth_weights_sides,
     &            smooth_weights_centers, k)

       Integer k
       Integer ilower0, iupper0
       Integer ilower1, iupper1

       Integer q_gcw
       real*8 q_data((ilower0-q_gcw):(iupper0+q_gcw),
     &              (ilower1-q_gcw):(iupper1+q_gcw))

       Integer r_gcw
       real*8 r_data_0((ilower0-r_gcw):(iupper0+r_gcw+1),
     &                  (ilower1-r_gcw):(iupper1+r_gcw),
     &                    0:1)
       real*8 r_data_1((ilower1-r_gcw):(iupper1+r_gcw+1),
     &                  (ilower0-r_gcw):(iupper0+r_gcw),
     &                    0:1)

       real*8 weights_cell_centers(0:k,0:(k-1))
       real*8 weights_cell_sides(0:k,0:(k-1))
       real*8 smooth_weights_centers(0:k-1)
       real*8 smooth_weights_sides(0:k-1)

       real*8 interp_values_p(0:k-1)
       real*8 interp_values_n(0:k-1)
       real*8 smooth_id_p(0:k-1)
       real*8 smooth_id_n(0:k-1)
       real*8 weights_p(0:k-1)
       real*8 weights_n(0:k-1)
       real*8 s_vals_x(ilower0-k:(iupper0+k),
     &                       (ilower1):(iupper1))
       real*8 s_vals_y(ilower1-k:(iupper1+k),
     &                       (ilower0):(iupper0))

       Integer i0, i1
       Integer j, r

       real*8 theta, new_weights_n(0:k-1), new_weights_p(0:k-1)
       real*8 weights_p_2(0:k-1), weights_n_2(0:k-1)
       real*8 sigma(0:1)
       Integer contains_neg

       real*8 eps, total, alpha

       contains_neg=0
       theta = 3.d0
       do j=0,(k-1)
         if (smooth_weights_centers(j) < 0) then
           contains_neg = 1
         endif
       enddo
       if (contains_neg == 1) then
         sigma(0) = 0.d0
         sigma(1) = 0.d0
         do j=0,k-1
           new_weights_p(j) = 0.5d0*(smooth_weights_centers(j)
     &       +theta*abs(smooth_weights_centers(j)))
           new_weights_n(j) = 0.5d0*(-smooth_weights_centers(j)
     &       +theta*abs(smooth_weights_centers(j)))
         enddo
         do j=0,k-1
           sigma(0) = sigma(0) + new_weights_p(j)
           sigma(1) = sigma(1) + new_weights_n(j)
         enddo
         do j = 0,k-1
           new_weights_p(j) = new_weights_p(j)/sigma(0)
           new_weights_n(j) = new_weights_n(j)/sigma(1)
         enddo
       endif

       eps = 1.0d-7
c       FIRST INTERPOLANT
c       X DIRECTION
       do i1 = ilower1, iupper1
         do i0 = ilower0-k, iupper0+k
           do r=0,k-1
             interp_values_p(r) = 0.d0
             interp_values_n(r) = 0.d0
             do j=0,k-1
               interp_values_p(r) = interp_values_p(r)
     &          + weights_cell_centers(r+1,j)*q_data(i0,i1+j-r)
             enddo
           enddo
           smooth_id_p(0) = 13.d0/12.d0*(q_data(i0,i1)
     &        -2.d0*q_data(i0,i1+1)+q_data(i0,i1+2))**2
     &        +0.25d0*(3.d0*q_data(i0,i1)
     &        -4.d0*q_data(i0,i1+1)+q_data(i0,i1+2))**2
           smooth_id_p(1) = 13.d0/12.d0*(q_data(i0,i1-1)
     &        -2.d0*q_data(i0,i1)+q_data(i0,i1+1))**2
     &        +0.25d0*(q_data(i0,i1-1)-q_data(i0,i1+1))**2
           smooth_id_p(2) = 13.d0/12.d0*(q_data(i0,i1-2)
     &        -2.d0*q_data(i0,i1-1)+q_data(i0,i1))**2
     &        +0.25d0*(q_data(i0,i1-2)
     &        -4.d0*q_data(i0,i1-1)+3.d0*q_data(i0,i1))**2
           total = 0.d0
           if (contains_neg == 0) then
!          WE DON"T NEED TO DO ANYTHING TO PRESERVE STABILITY
           do j=0,k-1
             alpha = smooth_weights_centers(j)
     &           /((eps+smooth_id_p(j))**2)
             total = total + alpha
             weights_p(j) = alpha
           enddo
           do j=0,k-1
             weights_p(j) = weights_p(j)/total
           enddo
           s_vals_x(i0,i1) = 0.d0
           do r=0,k-1
             s_vals_x(i0,i1) = s_vals_x(i0,i1)
     &         + weights_p(r)*interp_values_p(r)
           enddo
           else
!          WE HAVE A NEGATIVE WEIGHT
           total = 0.d0
           do j=0,k-1
             alpha = new_weights_p(j)
     &           /((eps+smooth_id_p(j))**2)
             total = total+alpha
             weights_p(j) = alpha
           enddo
           do j=0,k-1
             weights_p(j) = weights_p(j)/total
           enddo
           total = 0.d0
           do j=0,k-1
             alpha = new_weights_n(j)
     &           /((eps+smooth_id_p(j))**2)
             total = total+alpha
             weights_n(j) = alpha
           enddo
           do j=0,k-1
             weights_n(j) = weights_n(j)/total
           enddo
           s_vals_x(i0,i1) = 0.d0
           do r=0,k-1
             s_vals_x(i0,i1) = s_vals_x(i0,i1)
     &         + sigma(0)*weights_p(r)*interp_values_p(r)
     &         - sigma(1)*weights_n(r)*interp_values_p(r)
           enddo
           endif
         enddo
       enddo
c       Interpolate in other direction
c       X DIRECTION
      do i1 = ilower1, iupper1
        do i0=ilower0,iupper0+1
          do r=0,k-1
            interp_values_p(r) = 0.d0
            interp_values_n(r) = 0.d0
            do j=0,k-1
              interp_values_p(r) = interp_values_p(r)
     &          + weights_cell_sides(r,j)*s_vals_x(i0-r+j,i1)
              interp_values_n(r) = interp_values_n(r)
     &          + weights_cell_sides(r+1,j)*s_vals_x(i0-1-r+j,i1)
            enddo
          enddo
          smooth_id_p(0) = 13.d0/12.d0*(s_vals_x(i0,i1)
     &         -2.d0*s_vals_x(i0+1,i1)+s_vals_x(i0+2,i1))**2
     &      + 0.25d0*(3.d0*s_vals_x(i0,i1)-4.d0*s_vals_x(i0+1,i1)
     &         +s_vals_x(i0+2,i1))**2
          smooth_id_p(1) = 13.d0/12.d0*(s_vals_x(i0-1,i1)
     &        -2.d0*s_vals_x(i0,i1)+s_vals_x(i0+1,i1))**2
     &      + 0.25d0*(s_vals_x(i0-1,i1)-s_vals_x(i0+1,i1))**2
          smooth_id_p(2) = 13.d0/12.d0*(s_vals_x(i0-2,i1)
     &        -2.d0*s_vals_x(i0-1,i1)+s_vals_x(i0,i1))**2
     &      + 0.25d0*(3.d0*s_vals_x(i0,i1)-4.d0*s_vals_x(i0-1,i1)
     &        +s_vals_x(i0-2,i1))**2

          smooth_id_n(0) = 13.d0/12.d0*(s_vals_x(i0-1,i1)
     &        -2.d0*s_vals_x(i0,i1)+s_vals_x(i0+1,i1))**2
     &      + 0.25d0*(3.d0*s_vals_x(i0-1,i1)-4.d0*s_vals_x(i0,i1)
     &        +s_vals_x(i0+1,i1))**2
          smooth_id_n(1) = 13.d0/12.d0*(s_vals_x(i0-2,i1)
     &        -2.d0*s_vals_x(i0-1,i1)+s_vals_x(i0,i1))**2
     &      + 0.25d0*(s_vals_x(i0-2,i1)-s_vals_x(i0,i1))**2
          smooth_id_n(2) = 13.d0/12.d0*(s_vals_x(i0-3,i1)
     &        -2.d0*s_vals_x(i0-2,i1)+s_vals_x(i0-1,i1))**2
     &      + 0.25d0*(3.d0*s_vals_x(i0-1,i1)
     &        -4.d0*s_vals_x(i0-2,i1)+s_vals_x(i0-3,i1))**2

          total = 0.d0
           do j=0,k-1
             alpha = smooth_weights_sides(k-1-j)
     &           /(eps+smooth_id_p(j))**2
             total = total + alpha
             weights_p(j) = alpha
           enddo
           do j=0,k-1
             weights_p(j) = weights_p(j)/total
           enddo
           total = 0.d0
           do j=0,k-1
             alpha = smooth_weights_sides(j)
     &           /(eps+smooth_id_n(j))**2
             total = total + alpha
             weights_n(j) = alpha
           enddo
           do j=0,k-1
             weights_n(j) = weights_n(j)/total
           enddo
           r_data_0(i0,i1,0) = 0.d0
           r_data_0(i0,i1,1) = 0.d0
           do r=0,k-1
             r_data_0(i0,i1,0) = r_data_0(i0,i1,0)
     &               + weights_n(r)*interp_values_n(r)
             r_data_0(i0,i1,1) = r_data_0(i0,i1,1)
     &               + weights_p(r)*interp_values_p(r)
           enddo
         enddo
       enddo

c       INTERPOLATE IN Y DIRECTION

       do i0 = ilower0, iupper0
         do i1 = ilower1-k, iupper1+k
           do r=0,k-1
             interp_values_p(r) = 0.d0
             do j=0,k-1
               interp_values_p(r) = interp_values_p(r)
     &          + weights_cell_centers(r+1,j)*q_data(i0+j-r,i1)
             enddo
           enddo
           smooth_id_p(0) = 13.d0/12.d0*(q_data(i0,i1)
     &        -2.d0*q_data(i0+1,i1)+q_data(i0+2,i1))**2
     &        +0.25d0*(3.d0*q_data(i0,i1)
     &        -4.d0*q_data(i0+1,i1)+q_data(i0+2,i1))**2
           smooth_id_p(1) = 13.d0/12.d0*(q_data(i0-1,i1)
     &        -2.d0*q_data(i0,i1)+q_data(i0+1,i1))**2
     &        +0.25d0*(q_data(i0-1,i1)-q_data(i0+1,i1))**2
           smooth_id_p(2) = 13.d0/12.d0*(q_data(i0-2,i1)
     &        -2.d0*q_data(i0-1,i1)+q_data(i0,i1))**2
     &        +0.25d0*(q_data(i0-2,i1)
     &        -4.d0*q_data(i0-1,i1)+3.d0*q_data(i0,i1))**2
           if (contains_neg == 0) then
!          WE DON"T NEED TO DO ANYTHING SPECIAL
           total = 0.d0
           do j=0,k-1
             alpha = smooth_weights_centers(j)
     &           /((eps+smooth_id_p(j))**2)
             total = total + alpha
             weights_p(j) = alpha
           enddo
           do j=0,k-1
             weights_p(j) = weights_p(j)/total
           enddo
           s_vals_y(i1,i0) = 0.d0
           do r=0,k-1
             s_vals_y(i1,i0) = s_vals_y(i1,i0)
     &         + weights_p(r)*interp_values_p(r)
           enddo
           else
!          WE HAVE A NEGATIVE WEIGHT
           total = 0.d0
           do j=0,k-1
             alpha = new_weights_p(j)
     &           /((eps+smooth_id_p(j))**2)
             total = total+alpha
             weights_p(j) = alpha
           enddo
           do j=0,k-1
             weights_p(j) = weights_p(j)/total
           enddo
           total = 0.d0
           do j=0,k-1
             alpha = new_weights_n(j)
     &           /((eps+smooth_id_p(j))**2)
             total = total+alpha
             weights_n(j) = alpha
           enddo
           do j=0,k-1
             weights_n(j) = weights_n(j)/total
           enddo
           s_vals_y(i1,i0) = 0.d0
           do r=0,k-1
             s_vals_y(i1,i0) = s_vals_y(i1,i0)
     &         + sigma(0)*weights_p(r)*interp_values_p(r)
     &         - sigma(1)*weights_n(r)*interp_values_p(r)
           enddo
           endif
         enddo
       enddo
c       Interpolate in other direction
c       X DIRECTION
       do i1 = ilower1,iupper1+1
         do i0 = ilower0,iupper0
           do r=0,k-1
             interp_values_p(r) = 0.d0
             interp_values_n(r) = 0.d0
             do j=0,k-1
               interp_values_p(r) = interp_values_p(r)
     &          + weights_cell_sides(r,j)*s_vals_y(i1+j-r,i0)
               interp_values_n(r) = interp_values_n(r)
     &          + weights_cell_sides(r+1,j)*s_vals_y(i1-1+j-r,i0)
             enddo
           enddo
           smooth_id_p(0) = 13.d0/12.d0*(s_vals_y(i1,i0)
     &        -2.d0*s_vals_y(i1+1,i0)+s_vals_y(i1+2,i0))**2
     &        +0.25d0*(3.d0*s_vals_y(i1,i0)
     &        -4.d0*s_vals_y(i1+1,i0)+s_vals_y(i1+2,i0))**2
           smooth_id_p(1) = 13.d0/12.d0*(s_vals_y(i1-1,i0)
     &        -2.d0*s_vals_y(i1,i0)+s_vals_y(i1+1,i0))**2
     &        +0.25d0*(s_vals_y(i1-1,i0)-s_vals_y(i1+1,i0))**2
           smooth_id_p(2) = 13.d0/12.d0*(s_vals_y(i1-2,i0)
     &        -2.d0*s_vals_y(i1-1,i0)+s_vals_y(i1,i0))**2
     &        +0.25d0*(s_vals_y(i1-2,i0)
     &        -4.d0*s_vals_y(i1-1,i0)+3.d0*s_vals_y(i1,i0))**2

           smooth_id_n(0) = 13.d0/12.d0*(s_vals_y(i1-1,i0)
     &        -2.d0*s_vals_y(i1,i0)+s_vals_y(i1+1,i0))**2
     &        +0.25d0*(3.d0*s_vals_y(i1-1,i0)
     &        -4.d0*s_vals_y(i1,i0)+s_vals_y(i1+1,i0))**2
           smooth_id_n(1) = 13.d0/12.d0*(s_vals_y(i1-2,i0)
     &        -2.d0*s_vals_y(i1-1,i0)+s_vals_y(i1,i0))**2
     &        +0.25d0*(s_vals_y(i1-2,i0)-s_vals_y(i1,i0))**2
           smooth_id_n(2) = 13.d0/12.d0*(s_vals_y(i1-3,i0)
     &        -2.d0*s_vals_y(i1-2,i0)+s_vals_y(i1-1,i0))**2
     &        +0.25d0*(s_vals_y(i1-3,i0)
     &        -4.d0*s_vals_y(i1-2,i0)+3.d0*s_vals_y(i1-1,i0))**2
           total = 0.d0
           do j=0,k-1
             alpha = smooth_weights_sides(k-1-j)
     &           /((eps+smooth_id_p(j))**2)
             total = total + alpha
             weights_p(j) = alpha
           enddo
           do j=0,k-1
             weights_p(j) = weights_p(j)/total
           enddo
           total = 0.d0
           do j=0,k-1
             alpha = smooth_weights_sides(j)
     &           /((eps+smooth_id_n(j))**2)
             total = total + alpha
             weights_n(j) = alpha
           enddo
           do j=0,k-1
             weights_n(j) = weights_n(j)/total
           enddo
           r_data_1(i1,i0,0) = 0.d0
           r_data_1(i1,i0,1) = 0.d0
           do r=0,k-1
             r_data_1(i1,i0,0) = r_data_1(i1,i0,0)
     &         + weights_n(r)*interp_values_n(r)
             r_data_1(i1,i0,1) = r_data_1(i1,i0,1)
     &         + weights_p(r)*interp_values_p(r)
           enddo
         enddo
       enddo
       end subroutine
