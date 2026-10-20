-- Live-applied read-only service-role identity diagnostic. Restricted to server role.
CREATE OR REPLACE FUNCTION public.pulseops_integration_role_probe()
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$
 select jsonb_build_object(
   'effective_service_role', current_user = 'service_role',
   'jwt_claim_service_role', coalesce(current_setting('request.jwt.claim.role',true),'') = 'service_role'
 );
$function$
;
revoke all on function public.pulseops_integration_role_probe() from public,anon,authenticated;
grant execute on function public.pulseops_integration_role_probe() to service_role;