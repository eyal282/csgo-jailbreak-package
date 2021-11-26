/** Double-include prevention */
#if defined _customweapons_included_
  #endinput
#endif
#define _customweapons_included_

/**
 *
 * Özel silah kaydı yapmak için kullanılır.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
methodmap CustomWeapon < ArrayList
{
	/**
	 *
	 * Sınıfı başlatır.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native CustomWeapon(char[] weapon);

	/**
	 *
	 * Silahın özel kodunu değiştirir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetCode(char[] weapon);

	/**
	 *
	 * Silahın adını değiştir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetName(char[] name);

	/**
	 *
	 * Silahın ebeveyn silahını değiştir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetParentWeapon(char[] weapon);

	/**
	 *
	 * Silahın seslerini ekler.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void AddSound(char[] sound);

	/**
	 *
	 * Silahın Görünüm modelini değiştir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetViewModel(char[] viewModel);

	/**
	 *
	 * Silahın dünya modelini değiştir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetWorldModel(char[] worldModel);

	/**
	 *
	 * Silahın düşme modelini değiştir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetDroppedModel(char[] droppedModel);

	/**
	 *
	 * Silahın varsayılan cephane değiştir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetDefaultAmmo(int leftAmmo, int rightAmmo, int rightAmmoMax);

	/**
	 *
	 * Silahın dürbün zoom seviyesini değiştir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetMaxZoomLevel(int level);

	/**
	 *
	 * Silahın Çekme animasyonunu değiştir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetAnimationDraw(int sequence, float time);

	/**
	 *
	 * Silahın jarjör değiştirme animasyonunu değiştir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetAnimationReload(int sequence, float time);

	/**
	 *
	 * Silahın birincil saldırı animasyonunu değiştir.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetAnimationPrimaryAttack(int sequence1, int sequence2, float time);

	/**
	 *
	 * Silahın kaydını tamamlar.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native int Register();
}


/**
 *
 * Özel silahlar'ın mermilerini oluşturmak için kullanılır.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
methodmap Bullet < ArrayList
{
	/**
	 *
	 * Sınıfı başlatır.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native Bullet();
		
	/**
	 *
	 * Merminin sahibini ayarlar
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetOwner(int client);
	
	/**
	 *
	 * Merminin modelini ayarlar
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetModel(char[] model);
	
	/**
	 *
	 * Merminin hızını ayarlar
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetSpeed(float speed);
	
	/**
	 *
	 * Mermi'yi oluşturur.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native int Create();
	
	/**
	 *
	 * Mermiyi Ateşler
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native int Fire();
}

/**
 *
 * Patlama efektleri oluşturmak için kullanılır.
 *
 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
 *
 */
methodmap Explosion < ArrayList
{
	/**
	 *
	 * Sınıfı başlatır.
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native Explosion();
	
	/**
	 *
	 * Patlamanın merkezini ayarlar
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetOrigin(float origin[3]);
	
	/**
	 *
	 * Patlamanın sahibini ayarlar
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetOwner(int client);
	
	/**
	 *
	 * Patlama silahını ayarlar
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetWeapon(char[] weapon);
	
	/**
	 *
	 * Patlama varsayılan sesini ayarlar
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetDefaultSound(bool isActive);
	
	/**
	 *
	 * Patlama hasarını ayarlar
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetDamage(int damage);
	
	/**
	 *
	 * Patlama çapını ayarlar
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void SetRadius(int radius);
	
	/**
	 *
	 * Patlamayı Ateşler
	 *
	 * @author Ismail Satilmis <ismaiil_0234@hotmail.com>
	 *
	 */
	public native void Fire();
}
